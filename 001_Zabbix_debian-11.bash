#!/bin/bash

## INSTALL Zabbix on Debian 11 

echo "  +-------------------+----------------------------------------+-----------------------------------+--------------------------+-----------------+-------------+"
echo "  | VERSION DE ZABBIX | DISTRIBUTION DU SYSTÈME D'EXPLOITATION | VERSION DU SYSTÈME D’EXPLOITATION | COMPOSANT ZABBIX         | BASE DE DONNÉES | SERVEUR WEB |"
echo "  +-------------------+----------------------------------------+-----------------------------------+--------------------------+-----------------+-------------+"
echo "  | 6,0 LTS           | Debian                                 | 11 (Bullseye)                     | Serveur, Frontend, Agent | PostgreSQL      | Nginx       |"
echo "  +-------------------+----------------------------------------+-----------------------------------+--------------------------+-----------------+-------------+"

sleep 4 

check_distribution() {
    distribution=$(lsb_release -d | cut -f2)

    if [ "$distribution" = "Debian GNU/Linux 11 (bullseye)" ]; then
        echo "The distribution is compatible..."
    else
        read -p "The distribution is not Debian GNU/Linux 11 (bullseye). Do you want to continue despite the version incompatibility ? (yes/no): " choix_utilisateur

        if [ "$choix_utilisateur" = "yes" ] || [ "$choix_utilisateur" = "y" ]; then
            echo "Continuation of the script despite version incompatibility."
        else
            echo "Stopping the script."
            exit 1
        fi
    fi
}

# Appel de la fonction pour check la distribution 
check_distribution


# Fonction pour vérifier et installer les packets nécessaire
check_install_wget() {
    if command -v wget &> /dev/null; then
        echo "wget is already installed."
		echo "Proceeding with the script..."
    else
        echo "wget is not installed. Installing wget..."
         apt install wget -y
		 apt update
        echo "wget has been installed successfully."
		echo "Proceeding with the script..."
    fi
}

# Appel de la fonction pour vérifier et installer wget
check_install_wget

# Installer les packets sudo 
apt install sudo

# Fonction pour vérifier et désinstaller Apache2 si nécessaire
check_et_stop_apache2() {
    # Vérifier si Apache2 est installé
    if [ -x "$(command -v apache2)" ]; then
        # Apache2 est installé
        read -p "Apache2 is running. Do you want to stop it ? (yes/no) : " choix_utilisateur

        if [ "$choix_utilisateur" = "yes" ] || [ "$choix_utilisateur" = "y" ]; then
            # stop Apache2
           systemctl stop apache2
            echo "Apache2 was successfully stopped."
        else
            echo "Warning: Apache2 is not stopped this may cause conflicts with other system components (Nginx)."
        fi
    else
        echo "Apache2 is stoppd on your system. good..."
    fi
}

# Appel de la fonction pour vérifier et désinstaller Apache2
check_et_stop_apache2

## Install Zabbix repository
echo "Install Zabbix repository..."

# Téléchargement des packets zabbix pour debian 11
wget https://repo.zabbix.com/zabbix/6.0/debian/pool/main/z/zabbix-release/zabbix-release_6.4-1+debian11_all.deb

# Extraction des fichiers
dpkg -i zabbix-release_6.4-1+debian11_all.deb

# Mettez à jour la liste de paquets
apt update

# Install Zabbix server, frontend, agent
echo "Install Zabbix server, frontend, agent..."
apt install zabbix-server-pgsql zabbix-frontend-php php7.4-pgsql zabbix-nginx-conf zabbix-sql-scripts zabbix-agent postgresql postgresql-contrib zabbix-get

# Start cluster
pg_ctlcluster 13 main start
sleep 3

# Assurez-vous que le service est démarré:
echo "Ensure that the service is started"
systemctl start postgresql.service

# Création utilisateur zabbix et data base zabbix
 # Remplacez ceci par le véritable mot de passe Zabbix

function creer_utilisateur_zabbix() {
    local mot_de_passe_correct=false

    while [ "$mot_de_passe_correct" = false ]; do
        # Demander le mot de passe à l'utilisateur
        read -p "Please enter the Zabbix password : " mot_de_passe_utilisateur

        # Vérifier la longueur du mot de passe
        if [ ${#mot_de_passe_utilisateur} -ge 6 ]; then
            echo "Correct password."
			sleep 2
            mot_de_passe_correct=true
			
			echo "creation of the zabbix database zabbix user + privileges..."
			sleep 2 
            # On prend le rôle de l’utilisateur postgres et on utilise psql de manière non interactive
            sudo -u postgres psql -c "CREATE DATABASE zabbix;"

            # Création de l’utilisateur zabbix avec le mot de passe donné par l'utilisateur
            sudo -u postgres psql -c "CREATE USER zabbix WITH PASSWORD '$mot_de_passe_utilisateur';"

            # Ajout des privilèges pour l'utilisateur zabbix sur la bdd zabbix
            sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE zabbix TO zabbix;"
        else
            echo "Password too short. Please enter a password of at least 6 characters."
        fi
    done
}

# Appel de la fonction vérif mdp et création data base / utilisateur zabbix
creer_utilisateur_zabbix

echo "Creation of the Zabbix database OK"

# restart service postgresql
echo "restarting the postgresql service..."
systemctl restart postgresql

# reload service postgresql  
echo "reloading the postgresql service..."
systemctl reload postgresql


# Sur l'hôte du serveur Zabbix, importez le schéma et les données initiaux. 
# Vous serez invité à saisir votre mot de passe nouvellement créé le l'utilisateur zabbix.
echo "On the Zabbix server host, importing initial schemas and data..."

# Mettre en pause l'exécution du script pendant 3 secondes pour lire ci-dessus
sleep 3

zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix

## Configurer la base de données pour le serveur Zabbix

# Modifier le fichier /etc/zabbix/zabbix_server.conf
echo "You will be prompted to enter your newly created password for the zabbix user."
# Demander à l'utilisateur le mot de passe de la base de données Zabbix
read -sp "Please enter the Zabbix database password:" db_password

# Modifier le fichier de configuration de Zabbix pour mettre à jour le mot de passe
sed -i "s/# DBPassword=/DBPassword=${db_password}/" /etc/zabbix/zabbix_server.conf

# Afficher un message de confirmation
echo "The Zabbix database password has been successfully updated."

## Configurer PHP pour l'interface Zabbix

# Modifiez le fichier /etc/zabbix/nginx.conf, décommentez et définissez les directives 'listen' et 'server_name'.

# Fonction pour demander à l'utilisateur le port et l'IP pour l'interface web de Zabbix
demander_configuration_zabbix_for_nginx() {
    # Demander le port à l'utilisateur
    read -p "Please enter the port for the Zabbix web interface : " port_zabbix

    # Demander l'IP à l'utilisateur
    read -p "Please enter the IP for the Zabbix web interface :" ip_srv_zabbix

    # Modifier le fichier de configuration de Nginx pour Zabbix
    sudo sed -i "s/#\s*listen\s*8080;/	listen $port_zabbix;/g" /etc/zabbix/nginx.conf
    sudo sed -i "s/#\s*server_name\s*example.com;/	server_name $ip_srv_zabbix;/g" /etc/zabbix/nginx.conf

    echo "Zabbix web interface configuration updated successfully."
}

# Appeler la fonction
demander_configuration_zabbix_for_nginx


## Démarrez les processus du serveur et de l'agent Zabbix

# Démarrez les processus du serveur et de l'agent Zabbix et faites-les démarrer au démarrage du système.
echo "restart servicezabbix-server zabbix-agent nginx php7.4-fpm ..."
systemctl restart zabbix-server zabbix-agent nginx php7.4-fpm

echo "enable zabbix-server zabbix-agent nginx php7.4-fpm ..."
systemctl enable zabbix-server zabbix-agent nginx php7.4-fpm

# Ouvrir la page Web de l'interface utilisateur Zabbix

# Access the Zabbix Web UI
echo ""
echo "Now open the Zabbix web interface using the URL http://IP_address:Port."
echo ""
echo ""
# Début du blocklogo
blocklogo=$(cat <<'EOL'
                    _|        _|        _|                      _|            _|        _|                                    _|    _|
 _|_|_|_|    _|_|_|  _|_|_|    _|_|_|        _|    _|        _|_|_|    _|_|    _|_|_|          _|_|_|  _|_|_|                _|_|  _|_|
     _|    _|    _|  _|    _|  _|    _|  _|    _|_|        _|    _|  _|_|_|_|  _|    _|  _|  _|    _|  _|    _|  _|_|_|_|_|    _|    _|
   _|      _|    _|  _|    _|  _|    _|  _|    _|_|        _|    _|  _|        _|    _|  _|  _|    _|  _|    _|                _|    _|
 _|_|_|_|    _|_|_|  _|_|_|    _|_|_|    _|  _|    _|        _|_|_|    _|_|_|  _|_|_|    _|    _|_|_|  _|    _|                _|    _|
EOL
)

# Appliquer le formatage
echo -e "\e[1;31m\e[1m┌──────────────────────────────────────────────────────Create by NANDILLON Maxence──────────────────────────────────────────────────────┐\e[0m"
echo -e "\e[1;97m\e[1m $blocklogo \e[0m"
echo -e "\e[1;31m\e[1m└──────────────────────────────────────────────────────Create by NANDILLON Maxence──────────────────────────────────────────────────────┘\e[0m"
