#!/bin/sh

# 
# Script d'envoi de notification SMS via l'API Free Mobile
# https://github.com/C-Duv/freemobile-smsapi-client
# 
# Auteur: DUVERGIER Claude (http://claude.duvergier.fr)
# 
# Nécessite: curl
# 
# Possible usages:
#   send-notification.sh "All your base are belong to us"
#   echo "All your base are belong to us" | send-notification.sh
#   uptime | send-notification.sh

##
## Configuration utilisateur
##
if ! . ~/.freemobile-send-notification 
then 
	# Valeur par defaut

	# Login utilisateur / identifiant Free Mobile (celui utilisé pour
	# accéder à l'Espace Abonné)
	USER_LOGIN="1234567890"
	# Clé d'identification (générée et fournie par Free Mobile via
	# l'Espace Abonné, "Mes Options" :
	# https://mobile.free.fr/moncompte/index.php?page=options )
	API_KEY="s0me5eCre74p1K3y"
fi

# Valeur par defaut, si non definie dans la conf.

# Texte qui sera ajouté AVANT chaque message envoyé
MESSAGE_HEADER="${MESSAGE_HEADER-From $(hostname): }"

# Texte qui sera ajouté APRÈS chaque message envoyé
MESSAGE_FOOTER="${MESSAGE_FOOTER-}"

##
## Configuration système
##

# URL d'accès à l'API
SMSAPI_BASEURL=https://smsapi.free-mobile.fr
# Action d'envoi de notification
SMSAPI_SEND_ACTION=sendmsg

##
## Traitement du message
##

if [ -n "$*" ]; then
	# Message en tant qu'arguments de la ligne de commande
    MESSAGE_TO_SEND="$*"
else
	# Message lu depuis STDIN
	MESSAGE_TO_SEND="$(cat)"
fi
# Assemble header, message et footer
FINAL_MESSAGE_TO_SEND="$MESSAGE_HEADER$MESSAGE_TO_SEND$MESSAGE_FOOTER"
FINAL_MESSAGE_TO_SEND="${FINAL_MESSAGE_TO_SEND//"
"/ }"

##
## Appel à l'API (envoi)
##

# echo "Will send the following to $USER_LOGIN:" #DEBUG
# echo "$FINAL_MESSAGE_TO_SEND" #DEBUG

# --insecure : Certificat de $SMSAPI_BASEURL ne fourni pas
# --d'informations sur son propriétaire write-out "%{http_code}"
# ----silent --output /dev/null : Renvoi le code réponse HTTP
# --uniquement
HTTP_STATUS_CODE=$(curl --insecure \
	--get "$SMSAPI_BASEURL/$SMSAPI_SEND_ACTION" \
	--data "user=$USER_LOGIN" --data "pass=$API_KEY" \
	--data-urlencode "msg=$FINAL_MESSAGE_TO_SEND" \
	--write-out "%{http_code}" --silent --output /dev/null)

# Codes réponse HTTP possibles
# 200 : Le SMS a été envoyé sur votre mobile.
# 400 : Un des paramètres obligatoires est manquant.
# 402 : Trop de SMS ont été envoyés en trop peu de temps.
# 403 : Le service n'est pas activé sur l'espace abonné, 
#       ou login / clé incorrect(e).
# 500 : Erreur côté serveur. Veuillez réessayez ultérieurement.

if [ "$HTTP_STATUS_CODE" = 200 ]; then
    # echo "API responded with 200: exiting with 0" #DEBUG
    exit 0
else
    echo "Error: API responded with $HTTP_STATUS_CODE"
    exit 1
fi
