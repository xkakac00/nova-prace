#!/bin/bash 

# Vytvoření adresáře pro log soubor
mkdir -p "/home/kamil/Plocha/new-work/"

# Globální proměnné
actual_date=$(date +%Y-%m-%d-%H-%M) 
LOG_FILE="/home/kamil/Plocha/new-work/$actual_date-soubor.log"
RED='\033[0;31m' 
GREEN='\033[0;32m' 
NC='\033[0m'

# Funkce pro vytvoření hesla
function vytvorit_heslo(){
	local platforma="$1"
	local heslo="$2"

	# Kontrola, jestli proměnné nejsou prázdné
	if [ -z "$platforma" ] || [ -z "$heslo" ]; then
		echo -e "${RED}Chyba: Vstupy nesmí být prázdné!${NC}" | tee -a "$LOG_FILE"
		return 1
	else
		echo "$platforma":"$heslo" >> hesla.txt
	fi
}

# Funkce pro šifrování
function sifrovani(){
	local tajnyklic="$1"
	if [ -z "$tajnyklic" ]; then
		echo -e "${RED}Chyba: Vstup nesmí být prázdný!${NC}" | tee -a "$LOG_FILE"
		return 1
	else
		openssl enc -aes-256-cbc -salt -pbkdf2 -in hesla.txt -out hesla.txt.enc -k "$tajnyklic"
		if [ "$?" -eq 0 ] && [ -e hesla.txt.enc ]; then
			echo -e "${GREEN} Soubor s hesly byl úspěšně zašifrován ... [ PASS ] ${NC}" | tee -a "$LOG_FILE"
			rm -f hesla.txt
			if [ "$?" -eq 0 ] && [ ! -e hesla.txt ]; then
				echo -e "${GREEN} Nešifrovaný soubor byl právě smazán ... [ PASS ] ${NC}" | tee -a "$LOG_FILE"
			else
				echo -e "${RED} Nešifrovaný soubor nešlo smazat ... [ FAIL ] ${NC}" | tee -a "$LOG_FILE"
				return 1
			fi
		else
			echo -e "${RED} Soubor s hesly nešel vytvořit ... [ FAIL ] ${NC}" | tee -a "$LOG_FILE"
			return 1
		fi
	fi
}

# Funkce pro dešifrování
function desifrovani() {
	local tajnyklic="$1"
	if [ -z "$tajnyklic" ]; then
		echo -e "${RED}Chyba: Vstup nesmí být prázdný!${NC}" | tee -a "$LOG_FILE"
		return 1
	else
		if [ -e hesla.txt.enc ]; then  # Kontrola existence šifrovaného souboru
			openssl enc -d -aes-256-cbc -salt -pbkdf2 -in hesla.txt.enc -out hesla.txt -k "$tajnyklic"
			if [ "$?" -eq 0 ] && [ -e hesla.txt ]; then
				echo -e "${GREEN} Soubor s hesly byl úspěšně dešifrován ... [ PASS ] ${NC}" | tee -a "$LOG_FILE"
				rm -f hesla.txt.enc
				if [ "$?" -eq 0 ] && [ ! -e hesla.txt.enc ]; then
					echo -e "${GREEN} Starý šifrovaný soubor byl právě smazán ... [ PASS ] ${NC}" | tee -a "$LOG_FILE"
				else
					echo -e "${RED} Starý šifrovaný soubor nešlo smazat ... [ FAIL ] ${NC}" | tee -a "$LOG_FILE"
					return 1
				fi
			else
				echo -e "${RED} Soubor s hesly nešel dešifrovat ... [ FAIL ] ${NC}" | tee -a "$LOG_FILE"
				return 1
			fi
		else
			echo -e "${RED} Soubor s hesly neexistuje ... [ FAIL ] ${NC}" | tee -a "$LOG_FILE"
			return 1
		fi
	fi
}

# Funkce pro zobrazení hesla
function zobraz_heslo(){
	local tajnyklic="$1"
	local platforma="$2"

	if [ -z "$tajnyklic" ] || [ -z "$platforma" ]; then
		echo -e "${RED}Chyba: Vstupy nesmí být prázdné!${NC}" | tee -a "$LOG_FILE"
		return 1
	fi

	desifrovani "$tajnyklic"

	if [ -e hesla.txt ]; then
		existuje_heslo=$(grep -c "^$platforma:" hesla.txt)
		if [ "$existuje_heslo" -gt 0 ]; then
			grep "^$platforma:" hesla.txt | cut -d ":" -f2    # ^ - zacatek radku
		else
			echo "Pro platformu '$platforma' nebylo nalezeno žádné heslo!" | tee -a "$LOG_FILE"
		fi
		sifrovani "$tajnyklic"
	else
		echo -e "${RED}Soubor s hesly neexistuje ... [ FAIL ]${NC}" | tee -a "$LOG_FILE"
		return 1
	fi
}

# Funkce pro generování náhodného hesla
function nahodne_heslo(){
	heslo=$(tr -dc 'a-zA-Z0-9-!@#$%^&*()_+{}|:<>?=' < /dev/urandom | fold -w 10 | head -n1)
	echo "Náhodné heslo je: $heslo"
}

# Funkce pro ukončení programu
function konec(){
	echo "Program byl úspěšně ukončen" | tee -a "$LOG_FILE"
	exit 0
}

# Funkce pro změnu tajného klíče
function zmena_tajneho_klice(){
	if [ -e hesla.txt.enc ]; then
		desifrovani "$1"
		sifrovani "$2"
	else
		echo "Soubor neexistuje!" | tee -a "$LOG_FILE"
	fi
}

# Hlavní funkce
function main_flow(){
	echo "1) Vytvořit nové heslo"
	echo "2) Zobrazit existující heslo"
	echo "3) Generovat náhodné heslo"
	echo "4) Změna tajného klíče."
	echo "5) Konec"
	read volba

	case "$volba" in 
		1)
			echo "Zadejte platformu:"
			read platforma
			echo "Zadejte heslo:"
			read -s heslo
			vytvorit_heslo "$platforma" "$heslo"
			echo "Zadejte tajný klíč k šifrování"
			read -s tajnyklic
			sifrovani "$tajnyklic"
		;;
		2)
			if [ -e hesla.txt.enc ]; then  
				echo "Zadejte tajný klíč k dešifrování"
				read -s tajnyklic
				echo "Zadejte platformu, pro kterou chcete zjistit heslo"
				read platforma
				zobraz_heslo "$tajnyklic" "$platforma"
			else
				echo -e "${RED} Nemohu vypsat hesla, protože zašifrovaný soubor neexistuje ${NC}"
			fi
		;;
		3)
			nahodne_heslo
		;;
		4)
			echo "Zadej tajny klic pro desifrovani"
			read -s starytajnyklic
			echo "Zadej novy tajny klic pro sifrovani"
			read -s novytajnyklic
			zmena_tajneho_klice "$starytajnyklic" "$novytajnyklic"
		;;
		5)
			konec
		;;
		*)
			echo -e "${RED} Neplatná volba, spusťte šifrátor znovu. ${NC}"
		;;
	esac
}

# Hlavní tělo programu
main_flow
