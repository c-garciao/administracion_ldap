#!/bin/bash
#Script de alta de unidades organizativas. Creado por Carlos Garcia Oliva
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
  echo "Introduzca el nombre del dominio (patata.local)"
  read nombre_dominio
  if [ -z $nombre_dominio ]
  then
    echo -e "$(error) No ha introducido ningun nombre de dominio"
  else
    dc1=`echo $nombre_dominio | cut -d"." -f1`
    dc2=`echo $nombre_dominio | cut -d"." -f2`
    ldapsearch -xLLL -b "dc=$dc1,dc=$dc2" "(objectClass=organizationalUnit)" | grep ou: | awk '{print $2}' > uo.tmp ||  exit  \ || echo -e "$(error) No es correcto el nombre del dominio"
    echo -e "------\e[93mNombre de Unidades Organizativas en \e[91mUSO\e[0m:------"
    cat uo.tmp
    echo "-------------------------------------"
    echo -e "Inserte un nombre para la \e[92mnueva ud. organizativa\e[0m:"
    read nombre_uo
    if [ -z $nombre_uo ]
    then
      echo -e "$(error) No puede dejar vacio el campo"
    else
      existe_nombre=`cat uo.tmp | grep -w $nombre_uo | wc -l`
      if [[ $existe_nombre -ne 0 ]]
      then
        echo -e "$(error) Ya existe una ud organizativa con ese nombre"
      else
        echo "dn: ou=$nombre_uo,dc=$dc1,dc=$dc2">alta_ou.ldif
        echo "objectClass: organizationalUnit">>alta_ou.ldif
        echo "ou: $nombre_uo">>alta_ou.ldif
        ldapadd -x -W -D "cn=admin,dc=$dc1,dc=$dc2" -f alta_ou.ldif > /dev/nul  && echo "Se ha dado de alta la unidad organizativa \"$nombre_uo\"" \ || echo -e "$(error) No se ha dado de alta la unidad organizativa \"$nombre_uo\""
        rm -f alta_ou.ldif
        rm -f uo.tmp
      fi
    fi
  fi
fi
