#!/bin/bash
#Script de baja de unidades organizativas. Creado por Carlos Garcia Oliva
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
    echo -e "------\e[93mUnidades Organizativas en el servidor\e[0m:------"
    cat uo.tmp
    echo "-------------------------------------"
    echo "Inserte el nombre de la Unidad Organizativa:"
    read nombre_uo
    if [ -z $nombre_uo ]
    then
      echo -e "$(error) No puede dejar vacio el campo"
    else
      existe_nombre=`cat uo.tmp | grep -w $nombre_uo | wc -l`
      if [[ $existe_nombre -ne 1 ]]
      then
        echo -e "$(error) No existe una ud. organizativa con ese nombre"
      else
        #Comprobamos que no haya ningun objeto en la UO (si nos devuelve un 1, significa que esa linea es la de la propia UO, por lo que se podria borrar)
        #Si nos devuelve mas de 1 linea, significa que hay objetos en la UO y esta NO se puede borrar
        uo=`slapcat | grep ou=$nombre_uo,dc=$dc1,dc=$dc2 | wc -l`
        if [ $uo -le 0 ]
        then
          echo -e "$(error)"
        elif [ $uo -gt 1 ]
        then
          echo -e "$(error) Hay objetos en la ud. Organizativa \"$nombre_uo\" y NO se puede borrar"
        else
          ldapdelete -W -D "cn=admin,dc=$dc1,dc=$dc2" "ou=$nombre_uo,dc=$dc1,dc=$dc2" && echo "La ud Organizativa \"$nombre_uo\" se ha borrado correctamente" \ || echo -e "$(error) No se ha borrado la ud Organizativa \"$nombre_uo\""
        fi
      fi
    fi
  fi
fi
