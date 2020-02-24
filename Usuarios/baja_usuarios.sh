#!/bin/bash
#Script de baja de usuarios. Creado por Carlos Garcia Oliva
#Administracion de Sistemas en Red - Administracion de Sistemas 2018-2019
fecha () {
  date +"%d/%m/%Y-%H:%M:%S"
}
error (){
  echo -e "\e[91mError.\e[0m"
  #\e[91m corresponde al color rojo. \e[0m borra los atributos
  }
  #muestra_usuarios(){
  #  slapcat | grep -E "uid:" | awk '{print $2}' > usuarios.tmp
  #}
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
      slapcat | grep -E "uid:" | awk '{print $2}' > usuarios.tmp

      dc1=`echo $nombre_dominio | cut -d"." -f1`
      dc2=`echo $nombre_dominio | cut -d"." -f2`
      echo -e "------Escoja un usuario a \e[91meliminar\e[0m:------"
      cat usuarios.tmp
      echo "-------------------------------------"
      read usuario
      if [ -z $usuario ]
      then
        echo "$(error) No ha introducido ningun nombre"
      else
        existe=`cat usuarios.tmp | grep -w $usuario | wc -l`
        if [ $existe -ne 1 ]
        then
          echo -e "$(error) No existe el usuario \"$usuario\".Introduzca un usuario de la la lista"
        else
          #Obtenemos la ud Organizativa en la que esta el usuario
          ud_org=`slapcat | grep -E "uid=$usuario" | cut -d"=" -f3 | cut -d"," -f1`
	#echo "UID vale: $usuario UO es: $ud_org"
	#echo " -x -W -D 'cn=admin,dc=$dc1,dc=$dc2' "uid=$usuario,ou=$ud_org,dc=$dc1,dc=$dc2""
	#read tecla
          ldapdelete -W -D "cn=admin,dc=$dc1,dc=$dc2" "uid=$usuario,ou=$ud_org,dc=$dc1,dc=$dc2" && echo "El usuario \"$usuario\" se ha borrado correctamente" \ || echo -e "$(error) No se ha borrado el usuario \"$usuario\""
        fi
      fi
      rm -f usuarios.tmp
    fi
  fi
