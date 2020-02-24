#!/bin/bash
#Script de listado de usuarios. Creado por Carlos Garcia Oliva
#Administracion de Sistemas en Red - Administracion de Sistemas 2018-2019
fecha () {
  date +"%d/%m/%Y-%H:%M:%S"
}
error (){
  echo -e "\e[91mError.\e[0m"
  #\e[91m corresponde al color rojo. \e[0m borra los atributos
}
clear
if [[ $EUID -ne 0 ]]
then
  echo "$(error) Se debe ejecutar como superusuario"
else
  echo "Introduzca el nombre del dominio (patata.local):"
  read nombre_dominio
  if [ -z $nombre_dominio ]
  then
    echo -e "$(error) No ha introducido ningun nombre de dominio"
  else
    while :
    do
      clear
      slapcat | grep -E "uid:" | awk '{print $2}' > usuarios.tmp
      dc1=`echo $nombre_dominio | cut -d"." -f1`
      dc2=`echo $nombre_dominio | cut -d"." -f2`
      echo -e "------Escoja el usuario para \e[92mlistar\e[0m:------"
      cat usuarios.tmp
      echo "-------------------------------------"
      read usuario
      if [ -z $usuario ]
      then
        echo "$(error) No ha introducido ningun nombre"
        break
      else
        existe=`cat usuarios.tmp | grep -w $usuario | wc -l`
        if [ $existe -ne 1 ]
        then
          echo -e "$(error) No existe el usuario \"$usuario\".Introduzca un usuario de la la lista"
          break
        else
          #ldapsearch -xLLL -b "dc=$dc1,dc=$dc2" "(objectClass=inetOrgPerson)"
          ldapsearch -xLLL -b "dc=$dc1,dc=$dc2" "(uid=$usuario)" > usuario.tmp
          clear
          echo -e "Esta es la informacion del usuario: \e[42m$usuario\e[0m :\n"
          echo "**********************************************************"
          cat usuario.tmp | grep -E "dn:|uid:|uidNumber:|displayName:|gidNumber:|homeDirectory:|mail:"
          echo "**********************************************************"
        fi
      fi
      echo -e "\nDesea \e[43mconsultar\e[0m algun otro usuario (S/N)?"
      read opcion
      case $opcion in
        S)
          echo ""
        ;;
        N)
          rm -f usuario.tmp
          clear
          break
        ;;
        *)
          echo -e "$(error) Opcion no valida"
          rm -f usuario.tmp
          break
        ;;
      esac
    done
  fi
fi
