# Application de Navigation Routière

## Description
Cette application permet de détecter l’emplacement actuel de l’utilisateur en temps réel, d’afficher quatre points définis statiquement sur la carte, de calculer et d’afficher le chemin le plus rapide entre l’emplacement de l’utilisateur et un point d’arrivée en passant obligatoirement par un point intermédiaire, et d’indiquer les zones de congestion sur le trajet avec une couleur spécifique pour signaler les embouteillages.

## Instructions pour exécuter l'application

### 1. Installation de l'APK
- Téléchargez l'APK et installez-le sur votre appareil Android en cliquant sur le lien ci-dessous :
  [Télécharger l'APK](https://drive.google.com/file/d/1e65vRxtCaxvP3fTLUvjkbJn7kVCQ5xKR/view?usp=drive_link)

### 2. Clonage du dépôt
- Clonez le dépôt GitHub pour accéder au code source du projet :
  ```bash
  git clone https://github.com/HanaOuerghemmi/map_app


### 3.  Accédez au répertoire du projet
- Changez de répertoire vers le dossier du projet cloné  :
  ```bash
  cd map_app

### 4.  Installez les dépendances du projet
- Installez les dépendances nécessaires avec Flutter :

  ```bash
  flutter pub get

### 4.  Installez les dépendances du projet
- Installez les dépendances nécessaires avec Flutter :

  ```bash
  flutter pub get

### 5.  Lancez l'application
- Lancez l'application sur un émulateur ou un appareil physique :

  ```bash
  flutter run




### Choix techniques

#### Architecture
L'architecture de l'application suit un modèle simplifié de **MVC** (Modèle-Vue-Contrôleur), avec la gestion d'état via **Provider** pour une gestion fluide des états de l'application.

#### Gestion de la carte
Pour afficher des cartes, l'application utilise **flutter_map**, qui se base sur **OpenStreetMap**. Ce choix a été fait afin de ne pas dépendre de services payants, comme **Google Maps**, qui nécessitent une carte de paiement.

#### Localisation de l'utilisateur
La localisation est récupérée en temps réel grâce au package **geolocator**, qui permet de déterminer précisément la position GPS de l'utilisateur. Les permissions nécessaires sont gérées via **permission_handler**.

#### Gestion des itinéraires
L'application implémente un système de calcul d'itinéraires simulé en utilisant **OpenRouteService**, une API similaire à Google Maps. Cette solution a été choisie pour éviter les frais liés à l'utilisation de Google Maps.
