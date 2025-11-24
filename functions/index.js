/**
 * Cloud Functions - Marido de Aluguel
 * - Cria chat automaticamente quando booking vira "accepted"
 * - Atualiza lastMessage/lastTimestamp quando nova mensagem entra no chat
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * ===== 1) Quando um booking muda para ACCEPTED, cria/garante CHAT =====
 *
 * Coleções envolvidas:
 * bookings/{bookingId}
 * chats/{chatId}
 *
 * Estrutura esperada no booking:
 * clientId, clientName
 * providerId, providerName
 * serviceId, serviceName
 * status
 */
exports.createChatOnBookingAccepted = functions.firestore
    .document("bookings/{bookingId}")
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();
        const bookingId = context.params.bookingId;

        if (!before || !after) {
            return null;
        }

        // Só dispara quando muda de algo -> accepted
        if (before.status === "accepted" || after.status !== "accepted") {
            return null;
        }

        const clientId = after.clientId;
        const providerId = after.providerId;

        if (!clientId || !providerId) {
            console.log(
                "Booking sem clientId/providerId. bookingId:",
                bookingId,
            );
            return null;
        }

        // chatId único por par (cliente + prestador)
        const chatId = `${clientId}_${providerId}`;

        const chatRef = db.collection("chats").doc(chatId);
        const chatSnap = await chatRef.get();

        const createdAt = chatSnap.exists && chatSnap.data().createdAt
            ? chatSnap.data().createdAt
            : admin.firestore.FieldValue.serverTimestamp();

        // Dados base do chat
        const chatData = {
            chatId: chatId,
            clientId: clientId,
            providerId: providerId,
            participants: [clientId, providerId],
            serviceId: after.serviceId || null,
            serviceName: after.serviceName || null,
            bookingIds: admin.firestore.FieldValue.arrayUnion(bookingId),
            clientName: after.clientName || "Cliente",
            providerName: after.providerName || "Prestador",
            lastMessage: after.lastMessage || "",
            lastTimestamp: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            createdAt: createdAt,
        };

        await chatRef.set(chatData, {merge: true});

        if (!chatSnap.exists) {
            console.log("Chat criado:", chatId);
        } else {
            console.log("Chat atualizado (já existia):", chatId);
        }

        return null;
    });

/**
 * ===== 2) Quando cria mensagem, atualiza META do chat =====
 *
 * chats/{chatId}/messages/{messageId}
 *
 * Estrutura esperada da mensagem:
 * text, senderId, createdAt
 */
exports.updateChatLastMessage = functions.firestore
    .document("chats/{chatId}/messages/{messageId}")
    .onCreate(async (snap, context) => {
        const msg = snap.data();
        const chatId = context.params.chatId;

        if (!msg) {
            return null;
        }

        const text = msg.text || "";
        const senderId = msg.senderId || null;
        const createdAt = msg.createdAt ||
            admin.firestore.FieldValue.serverTimestamp();

        const chatRef = db.collection("chats").doc(chatId);

        await chatRef.set(
            {
                lastMessage: text,
                lastSenderId: senderId,
                lastTimestamp: createdAt,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            {merge: true},
        );

        return null;
    });

/**
 * (Opcional) HTTP function simples pra testar se Functions está OK
 */
exports.ping = functions.https.onRequest((req, res) => {
    res.status(200).send("Functions OK ✅");
});
