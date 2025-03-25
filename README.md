# Application de Navigation Routière

## Description
Cette application permet de détecter l’emplacement actuel de l’utilisateur en temps réel, d’afficher quatre points définis statiquement sur la carte, de calculer et d’afficher le chemin le plus rapide entre l’emplacement de l’utilisateur et un point d’arrivée en passant obligatoirement par un point intermédiaire, et d’indiquer les zones de congestion sur le trajet avec une couleur spécifique pour signaler les embouteillages.

## Instructions pour exécuter l'application

### Installation

0. Installer l'APK sur votre appareil.

[Télécharger l'APK](https://drive.google.com/file/d/1e65vRxtCaxvP3fTLUvjkbJn7kVCQ5xKR/view?usp=drive_link) 

1. Cloner le dépôt:
   ```bash
   git clone [URL_DU_DEPOT]

### Choix techniques

#### Architecture
L'architecture de l'application suit un modèle simplifié de **MVC** (Modèle-Vue-Contrôleur), avec la gestion d'état via **Provider** pour une gestion fluide des états de l'application.

#### Gestion de la carte
Pour afficher des cartes, l'application utilise **flutter_map**, qui se base sur **OpenStreetMap**. Ce choix a été fait afin de ne pas dépendre de services payants, comme **Google Maps**, qui nécessitent une carte de paiement.

#### Localisation de l'utilisateur
La localisation est récupérée en temps réel grâce au package **geolocator**, qui permet de déterminer précisément la position GPS de l'utilisateur. Les permissions nécessaires sont gérées via **permission_handler**.

#### Gestion des itinéraires
L'application implémente un système de calcul d'itinéraires simulé en utilisant **OpenRouteService**, une API similaire à Google Maps. Cette solution a été choisie pour éviter les frais liés à l'utilisation de Google Maps.
