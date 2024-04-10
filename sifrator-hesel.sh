#!/bin/bash 

#globalni promene
actual_date=$(date +%Y-%d-%m-%H-%M)
LOG_FILE="/home/kamil/Plocha/new-work/$actual_date-soubor.log"
RED='\033[031m'
GREEN='\033[032m'
NC='\033[0m'

function vytvorit_heslo(){
	local platforma="$1"
	local heslo="$2"

	# Kontrola, jestli promene nejsou prazdne
	if [ -z "$platforma" ] || [ -z "$heslo" ];then
		echo -e "${RED}Chyba:Vstupy nesmí být prázdné!${NC}" | tee -a "$LOG_FILE"
		exit 1
	else
		echo "$platforma":"$heslo" >> hesla.txt
	fi
}

function sifrovani(){
	local tajnyklic="$1"
	if [ -z "$tajnyklic" ];then
		echo -e "${RED}Chyba:Vstup nesmí být prázdný!${NC}" | tee -a "$LOG_FILE"
		exit 1
	else
		openssl enc -aes-256-cbc -salt -pbkdf2 -in hesla.txt -out hesla.txt.enc -k "$tajnyklic"
		if [ "$?" -eq 0 ] && [ -e hesla.txt.enc ];then
			echo -e "${GREEN} Soubor s hesly byl úspěšně zašifrován ... [ PASS ] ${NC}" | tee -a "$LOG_FILE"
			rm -f hesla.txt
			if [ "$?" -eq 0 ] && [ ! -e hesla.txt ];then
				echo -e "${GREEN} Nešifrovaný soubor byl právě smazán ... [ PASS ] ${NC}" | tee -a "$LOG_FILE"
			else
				echo -e "${RED} Nešifrovaný soubor nešlo smazat ... [ FAIL ] ${NC}" | tee -a "$LOG_FILE"
				exit 1
			fi
		else
			echo -e "${RED} SOubor s hesly nešel vytvořit ... [ FAIL ] ${NC}" | tee -a "$LOG_FILE"
			exit 1
		fi
	fi

}

function desifrovani (){
	local tajnyklic="$1"
	if [ -z "$tajnyklic" ];then
		echo -e "${RED}Chyba:Vstup nesmí být prázdný!${NC}" | tee -a "$LOG_FILE"
		exit 1
	else
	      	openssl enc -d -aes-256-cbc -salt -pbkdf2 -in hesla.txt.enc -out hesla.txt -k "$tajnyklic"
		if [ "$?" -eq 0 ] && [ -e hesla.txt ];then
			echo -e "${GREEN} Soubor s hesly byl úspěšně dešifrován ... [ PASS ] ${NC}" | tee -a "$LOG_FILE"
			rm -f hesla.txt.enc
			if [ "$?" -eq 0 ] && [ ! -e hesla.txt.enc ];then
				echo -e "${GREEN} Starý šifrovaný soubor byl právě smazán ... [ PASS ] ${NC}" | tee -a "$LOG_FILE"
			else	
				echo -e "${RED} Starý šifrovaný soubor nešlo smazat ... [ FAIL ] ${NC}" | tee -a "$LOG_FILE"
				exit 1
			fi
		fi
	fi
}	

function zobraz_heslo(){
	local platforma="$2"
	desifrovani "$1"
	if [ -z "$platforma" ];then
		echo "Chyba: Vstup nesmí být prázdný!" | tee -a "$LOG_FILE"
	else
		existuje_heslo=$(cat hesla.txt | grep "$platforma" | cut -d ":" -f1 | wc -l)
		if [ "$existuje_heslo" -gt 0 ];then
			cat hesla.txt | grep "$platforma" | cut -d ":" -f2
		else
			echo "Pro platformu '$platforma' nebylo nalezeno, žádné heslo!" | tee -a "$LOG_FILE"
		fi
	fi
	sifrovani
}

function nahodne_heslo(){
	heslo=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9-!@#$%^&*()_+{}|:<>?=' | fold -w 10 | head -n1)
	echo "Náhodné heslo je:$heslo" 
}
function konec(){
	echo "Program byl úspěšně ukončen" | tee -a "$LOG_FILE"
	exit 1
}

function zmena_tajneho_klice(){
	desifrovani "$1"
	sifrovani "$2"
}
function main_flow(){
	echo "1) Vytvořit nové heslo"
	echo "2) Zobrazit existující heslo"
	echo "3) Generovat náhodné heslo"
	echo "4) Změna tajného klíče."
	echo "5) Konec"
	read volba
	
	case "$volba" in 
	 	1)
		 #Zapíše platformu a heslo, které se uloží do souboru a následně zašifruje pomoci tajneho klice
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
		#Soubor s hesly se rozsifruje, uzivatel napise platformu a skript mu vypise heslo a nasledne se znovu zasifruje pomoci tajneho klice.
		 if [ -e hesla.txt.enc ];then
		    echo -e "${RED} Nemohu vypsat hesla, protože zašifrovaný soubor neexistuje ${NIC}"
		 else
			 echo "Zadejte tajný klíč k dešifrování"
		         read -s tajnyklic
		 	 echo "Zadejte platformu, pro kterou chcete zjistit heslo"
		         read platforma
			 zobraz_heslo "$tajnyklic" "$platforma"
			 sifrovani "$tajnyklic"
		 fi
	;;
		3)
		# Vygeneruje se nahodne heslo pomoci /dev/urandom
		 nahodne_heslo
 	;;
		4)
		# Nejdrive je potrebne zadat stary tajny klic pro desifrovani a novym tajnym klicem potom zasifrovat	
		echo "Zadej tajny klic pro desifrovani"
		read -s starytajnyklic
		echo "Zadej novy tajny klic pro sifrovani"
		read -s novytajnyklic
		zmena_tajneho_klice starytajnyklic novytajnyklic				
	;;
		5)
		# Skript se ukonci s chybovym kodem 1
		 konec
	;;	
		*)
		echo "{RED} Neplatná volba, spuste šifrator znovu. ${NIC}"
	;;
	esac
}

# hlavni telo programu
main_flow

