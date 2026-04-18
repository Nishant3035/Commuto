const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

// -- 1. Generate OTP for new rides --
exports.generateRideOtp = onDocumentCreated("rides/{rideId}", async (event) => {
    const rideId = event.params.rideId;
    const otp = Math.floor(1000 + Math.random() * 9000).toString(); // 4-digit code

    // Store in a private sub-collection for security
    await db.collection("rides").doc(rideId).collection("private").doc("data").set({
        otp_code: otp,
        created_at: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log(`Generated OTP for ride ${rideId}`);
});

// -- 2. Secure OTP Verification --
exports.verifyBookingOtp = onCall(async (request) => {
    // Check authentication
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "User must be logged in.");
    }

    const { bookingId, otp } = request.data;
    if (!bookingId || !otp) {
        throw new HttpsError("invalid-argument", "Missing bookingId or otp.");
    }

    const bookingRef = db.collection("bookings").doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
        throw new HttpsError("not-found", "Booking not found.");
    }

    const bookingData = bookingDoc.data();
    const rideId = bookingData.ride_id;
    const riderId = bookingData.rider_id;

    // Authorized as part of the booking
    if (request.auth.uid !== riderId) {
        throw new HttpsError("permission-denied", "Only the rider can verify the OTP.");
    }

    // Get the private OTP and check it
    const privateDoc = await db.collection("rides").doc(rideId).collection("private").doc("data").get();
    if (!privateDoc.exists) {
        throw new HttpsError("failed-precondition", "Ride OTP not available.");
    }

    const actualOtp = privateDoc.data().otp_code;

    if (otp === actualOtp) {
        // SUCCESS: Update booking and decrement ride seats
        const rideRef = db.collection("rides").doc(rideId);

        try {
            await db.runTransaction(async (transaction) => {
                const rideDoc = await transaction.get(rideRef);
                if (!rideDoc.exists) throw new Error("Ride not found");

                const rideData = rideDoc.data();
                const seatsAvailable = rideData.seats_available;

                if (seatsAvailable <= 0) {
                    throw new Error("No seats available.");
                }

                // Update Booking
                transaction.update(bookingRef, {
                    booking_status: "confirmed",
                    otp_verified: true,
                    verified_at: admin.firestore.FieldValue.serverTimestamp()
                });

                // Update Ride
                const newSeats = seatsAvailable - 1;
                transaction.update(rideRef, {
                    seats_available: newSeats,
                    ride_status: newSeats === 0 ? "full" : "active"
                });
            });

            return { success: true, message: "Booking confirmed!" };
        } catch (error) {
            console.error("Verification Transaction Failed:", error);
            throw new HttpsError("internal", error.message || "Failed to confirm booking.");
        }
    } else {
        return { success: false, message: "Invalid OTP code." };
    }
});

// -- 3. Notifications --

// Notify driver when someone requests to join
exports.onBookingCreated = onDocumentCreated("bookings/{bookingId}", async (event) => {
    const bookingData = event.data.data();
    const rideId = bookingData.ride_id;

    const rideDoc = await db.collection("rides").doc(rideId).get();
    if (!rideDoc.exists) return;

    const driverId = rideDoc.data().driver_id;
    const driverProfile = await db.collection("users").doc(driverId).get();
    
    if (driverProfile.exists && driverProfile.data().fcm_token) {
        const token = driverProfile.data().fcm_token;
        const message = {
            notification: {
                title: "New Ride Request!",
                body: "Someone wants to join your ride. View details to accept."
            },
            token: token
        };
        await messaging.send(message);
    }
});

// Notify rider when booking is confirmed
exports.onBookingUpdated = onDocumentUpdated("bookings/{bookingId}", async (event) => {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();

    // Only notify on confirmation
    if (beforeData.booking_status === "pending" && afterData.booking_status === "confirmed") {
        const riderId = afterData.rider_id;
        const riderProfile = await db.collection("users").doc(riderId).get();

        if (riderProfile.exists && riderProfile.data().fcm_token) {
            const token = riderProfile.data().fcm_token;
            const message = {
                notification: {
                    title: "Booking Confirmed! ✅",
                    body: "Your ride has been successfully booked. Have a safe journey!"
                },
                token: token
            };
            await messaging.send(message);
        }
    }
});
