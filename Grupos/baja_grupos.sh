#!/bin/bash
#Script de baja de grupos. Creado por Carlos Garcia Oliva
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
    ldapsearch -xLLL -b "dc=$dc1,dc=$dc2" "(objectClass=posixGroup)" | grep -E  "gidNumber|cn:" > grupos.tmp ||  exit  \ || echo -e "$(error) No es correcto el nombre del dominio"
    echo -e "------\e[93mGrupos en el servidor\e[0m:------"
    #Imprimimos las lineas pares (%2==0) con awk. Son las lineas que contienen el nombre del grupo. Nos quedamos solo con el nombre (cut -d":")
    cat grupos.tmp | awk 'NR%2==0' | cut -d ":" -f2
    echo "-------------------------------------"
    echo "Inserte el nombre del grupo:"
    read nombre_grupo
    if [ -z $nombre_grupo ]
    then
      echo -e "$(error) No puede dejar vacio el campo"
    else
      existe_nombre=`cat grupos.tmp | grep -w $nombre_grupo | wc -l`
      if [[ $existe_nombre -eq 0 ]]
      then
        echo -e "$(error) No existe un grupo con ese nombre"
      else
        gid_grupo=`ldapsearch -xLLL -b "cn=$nombre_grupo,ou=grupos,dc=$dc1,dc=$dc2" | grep gidNumber | awk '{print $2}'`
        ldapsearch -xLLL -b "ou=usuarios,dc=$dc1,dc=$dc2" | grep uid: | awk '{print $2}' > usuarios.tmp
        while read i
        do
          grupo_usuario=`ldapsearch -xLLL -b "uid=$i,ou=usuarios,dc=$dc1,dc=$dc2" | grep gidNumber | awk '{print $2}'`
          if [ $grupo_usuario -eq $gid_grupo ]
          then
            echo -e "$(error) No se puede borrar el grupo \"$nombre_grupo\". Tiene usuarios"
            exit && rm -f usuario.tmp
            break
          fi
        done < usuarios.tmp
        ldapdelete -W -D "cn=admin,dc=$dc1,dc=$dc2" "cn=$nombre_grupo,ou=grupos,dc=$dc1,dc=$dc2" && echo "El grupo \"$nombre_grupo\" se ha borrado correctamente" \ || echo -e "$(error) No se ha borrado el grupo \"$nombre_grupo\""
      fi
    fi
  fi
fi
