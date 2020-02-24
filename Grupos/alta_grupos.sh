#!/bin/bash
#Script de alta de grupos. Creado por Carlos Garcia Oliva
#Administracion de Sistemas en Red - Administracion de Sistemas 2018-2019
fecha () {
  date +"%d/%m/%Y-%H:%M:%S"
}
error (){
  echo -e "\e[91mError.\e[0m"
  #\e[91m corresponde al color rojo. \e[0m borra los atributos
}
gid_num(){
  gid_generado=`ldapsearch -xLLL -b "dc=$dc1,dc=$dc2" "(objectClass=posixGroup)" | grep "gidNumber" | awk '{print $2}' | sort -n -r | head -n1`
  let gid_generado=gid_generado+1
  echo $gid_generado
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
    ldapsearch -xLLL -b "dc=$dc1,dc=$dc2" "(objectClass=posixGroup)" | grep -E  "gidNumber|cn:" > grupos.tmp
    echo -e "------Nombre de grupo en \e[93mUSO\e[0m:------"
    #Imprimimos las lineas pares (%2==0) con awk. Son las lineas que contienen el nombre del ggrupo. Nos quedamos solo con el nombre (cut -d":")
    cat grupos.tmp | awk 'NR%2==0' | cut -d ":" -f2
    echo "-------------------------------------"
    echo "Inserte un nombre para el grupo:"
    read nombre_grupo
    if [ -z $nombre_grupo ]
    then
      echo -e "$(error) No puede dejar vacio el campo"
    else
      existe_nombre=`cat grupos.tmp | grep -w $nombre_grupo | wc -l`
      if [[ $existe_nombre -ne 0 ]]
      then
        echo -e "$(error) Ya existe un grupo con ese nombre"
      else
        #Listamos todos lo GID y los volcamos a un fichero temporal
        # ldapsearch -xLLL -b "dc=$dc1,dc=$dc2" "(objectClass=posixGroup)" | grep -E  "gidNumber|cn:" > grupos.tmp
        # echo -e "------GID en \e[93mUSO\e[0m:------"
        # #Imprimimos las lineas impares (%2==1) con awk. Son las lineas que contienen el gid. Nos quedamos solo con el numero (cut -d":")
        # cat grupos.tmp | awk 'NR%2==1' | cut -d ":" -f2
        # echo "-------------------------------------"
        # echo "Inserte un nuevo GID para el grupo $nombre_grupo:"
        # read grupo
        # existe=`cat grupos.tmp | grep -w $grupo | wc -l`
        # if [ -z $grupo ]
        # then
        #   echo -e "$(error) No puede dejar el campo vacio"
        # elif ! [[ "$grupo" =~ ^[0-9]+$ ]]
        # then
        #   echo "$(error) El gid SOLO puede contener numeros"
        #   #comprobamos que no exista un grupo con ese gid (si es DISTINTO de 0 [ne], es porque existe el grupo)
        # elif [[ $existe -ne 0 ]]
        # then
        #   echo -e "$(error) Ya existe un grupo con ese gid"
        # else
        echo "dn: cn=$nombre_grupo,ou=grupos,dc=$dc1,dc=$dc2" >insertar_grupo.ldif
        echo "objectClass: top" >>insertar_grupo.ldif
        echo "objectClass: posixGroup" >>insertar_grupo.ldif
        echo "gidNumber: $(gid_num)" >>insertar_grupo.ldif
        ldapadd -x -W -D "cn=admin,dc=$dc1,dc=$dc2" -f insertar_grupo.ldif > /dev/nul  && echo "Se ha dado de alta el grupo \"$nombre_grupo\" correctamente" \ || echo -e "$(error) No se ha dado de alta el grupo \"$nombre_grupo\""
        rm -f insertar_grupo.ldif
        rm -f grupos.tmp
      fi
    fi
  fi
fi
#fi
