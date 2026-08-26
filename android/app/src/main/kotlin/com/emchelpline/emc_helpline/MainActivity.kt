package com.emchelpline.emc_helpline

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    /**
     * Empêche les captures d'écran et la vignette du sélecteur d'applications.
     *
     * Toute la conception part d'une prémisse : le téléphone est souvent
     * partagé, parfois avec la personne que l'on signale. Rien n'est écrit sur
     * le disque, le numéro de référence n'est jamais stocké en clair — puis
     * Android photographie l'écran courant pour la vignette du multitâche, et
     * n'importe qui peut capturer le récit en cours de saisie. C'était le
     * maillon manquant du raisonnement.
     *
     * Posé sur l'application entière plutôt que sur le seul formulaire :
     * l'écran de suivi affiche un statut de dossier, et l'assistant une
     * conversation.
     */
    override fun onCreate(savedInstanceState: Bundle?) {
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
        super.onCreate(savedInstanceState)
    }
}
