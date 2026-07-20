const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendNotificationOnCreate = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    const notificationId = context.params.notificationId;
    const notificationData = snap.data();
    const userId = notificationData.userId;

    // Kiểm tra xem đã gửi FCM cho notification này chưa (chống trùng lặp)
    if (notificationData.fcmSent === true) {
      console.log("FCM already sent for this notification");
      return null;
    }

    // Get the receiver's FCM token from Firestore
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    if (!userDoc.exists) {
      console.log("User not found");
      return null;
    }

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) {
      console.log("No FCM token for user");
      return null;
    }

    // Create FCM message (only data, no notification - let Flutter handle display)
    const message = {
      data: {
        title: notificationData.title,
        body: notificationData.body,
        ...notificationData.payload,
      },
      token: fcmToken,
      android: {
        priority: "high",
      },
    };

    // Send FCM message
    try {
      const response = await admin.messaging().send(message);
      console.log("Successfully sent message:", response);
      
      // Đánh dấu là đã gửi FCM để không gửi lại
      await admin.firestore().collection("notifications").doc(notificationId).update({
        fcmSent: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      return response;
    } catch (error) {
      console.log("Error sending message:", error);
      return null;
    }
  });
