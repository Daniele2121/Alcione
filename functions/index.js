const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");

// Inizializza l'app Admin per avere i permessi di invio
initializeApp();

exports.notificanuovogiocatore = onDocumentCreated("giocatori/{giocatoreId}", async (event) => {
    // 1. Recupera i dati del giocatore appena salvato
    const dati = event.data.data();

    // Se per qualche motivo i dati sono vuoti, esci
    if (!dati) return null;

    // 2. Costruisci il messaggio "Stile Professionale"
    const payload = {
        notification: {
            title: '⚽ NUOVO TALENTO ALCIONE',
            body: `Segnalato: ${dati.cognome} ${dati.nome} (${dati.ruolo})`,
        },
        // Configurazione specifica per ANDROID
        android: {
            priority: 'high', // Forza la comparsa immediata
            notification: {
                channelId: 'importante', // Nome del canale (deve coincidere con l'app)
                icon: 'stock_ticker_update', // Icona di sistema (o la tua personalizzata)
                color: '#FF6600', // Arancione Alcione
                sound: 'default',
                clickAction: 'FLUTTER_NOTIFICATION_CLICK', // Apre l'app al click
            },
        },
        // Configurazione specifica per APPLE (iOS)
        apns: {
            payload: {
                aps: {
                    alert: {
                        title: '⚽ NUOVO TALENTO ALCIONE',
                        body: `Segnalato: ${dati.cognome} ${dati.nome} (${dati.ruolo})`,
                    },
                    sound: 'default',
                    badge: 1, // Mostra il numerino sull'icona dell'app
                },
            },
        },
        // Il "canale" a cui tutti i telefoni degli scout sono iscritti
        topic: 'segnalazioni',
    };

    try {
        // 3. Spedisci la notifica a tutti gli iscritti
        const response = await getMessaging().send(payload);
        console.log(`✅ Notifica inviata con successo! ID: ${response}`);
    } catch (error) {
        console.error("❌ Errore durante l'invio della notifica:", error);
    }
});