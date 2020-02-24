#!/bin/bash
#Script de alta de usuarios. Creado por Carlos Garcia Oliva
#Administracion de Sistemas en Red - Administracion de Sistemas 2018-2019
fecha () {
  date +"%d/%m/%Y-%H:%M:%S"
}
error (){
  echo -e "\e[91mError.\e[0m"
  #\e[91m corresponde al color rojo. \e[0m borra los atributos
}
#Listamos todos los uid y los ordenamos de MAYOR a MENOR. Nos quedamos con el primero (el mayor de TODOS, y lo guradamos en una variable).
#Posteriormente, le sumamos 1.Con esta funcion, el uid es siempre unico (el primer usuario debemos asignarle manualmente el uid 2000)
generar_uid(){
  uid_generado=`slapcat | grep uidNumber | cut -d":" -f2 | sort -n -r | head -n1`
  let uid_generado=uid_generado+1
  #return $uid_generado
  echo "$uid_generado"
}
clear
if [[ $EUID -ne 0 ]]
then
  echo "$(error) Se debe ejecutar como superusuario"
else
  #Pedimos por teclado las variables y comprobamos que no esten vacias(-z)
  echo "Introduzca el nombre del dominio (patata.local)"
  read nombre_dominio
  if [ -z $nombre_dominio ]
  then
    echo -e "$(error) No ha introducido ningun nombre de dominio"
  else
    echo "Introduzca el nombre de la Unidad Organizativa"
    read n_ou
    if [ -z $n_ou ]
    then
      echo -e "$(error) No ha introducido ninguna Unidad Organizativa"
    else
      echo "Introduzca su nombre y primer apellido (separados por un espacio):"
      read nomb_ape
      nombre=`echo $nomb_ape | cut -d " " -f1`
      apellido=`echo $nomb_ape | cut -d " " -f2`
      if [ -z $nombre -o -z $apellido ]
      then
        echo "$(error) No ha introducido ningun nombre o apellido"
      else
        echo "Introduzca su contraseña"
        #El modificador -s no muestra por pantalla la contraseña a la hora de escribirla
        read -s contrasenia
        if [ -z $contrasenia ]
        then
          echo -e "$(error) No ha introducido ninguna contraseña"
        else
          ###################################################Definicion de variables y tratamiento de datos###################################################
          #Almacenamos en variables el nombre del dominio (ej. dc=carlos, dc=local)
          dc1=`echo $nombre_dominio | cut -d"." -f1`
          dc2=`echo $nombre_dominio | cut -d"." -f2`
          #Nos quedamos con la primera letra del nombre para formar el uid
          uid1=`echo $nombre | cut -c1`
          #Concatenamos con el apellido(+= concatena)
          uid1+=`echo $apellido`
          #echo -e "Vd ha introducido:\n\tNombre_Dominio:$nombre_dominio\n\tNombre_OU:$n_ou\n\tNombre:$nombre\n\tContraseña:$contrasenia"
          #echo -e "\tUid:$uid1\n\tdc=$dc1,dc=$dc2"
          #Transformamos la primera letra del nombre y del apellido a mayusculas
          nombre="${nombre^}"
          apellido="${apellido^}"
          #Convertimos nombre y apellido a minusculas
          nombre_m="${nombre,,}"
          apellido_m="${apellido,,}"
          disp_name=`echo $nombre $apellido`
          #echo -e "\tNombre:$nombre\n\tApellido:$apellido\n\tDisplay Name:$disp_name"
          #Redireccionando con > en lugar de >> nos aseguramos que siempre que ejecutemos el script, el archivo ldif lo sobreescribira, evitando problemas
          echo "dn: uid=$uid1,ou=$n_ou,dc=$dc1,dc=$dc2" > alta_usuario.ldif
          echo "objectClass: inetOrgPerson" >> alta_usuario.ldif
          echo "objectClass: posixAccount" >> alta_usuario.ldif
          echo "objectClass: shadowAccount" >> alta_usuario.ldif
          echo "uid: $uid1" >> alta_usuario.ldif
          echo "sn: $apellido" >> alta_usuario.ldif
          echo "givenName: $nombre" >> alta_usuario.ldif
          echo "cn: $disp_name" >> alta_usuario.ldif
          echo "displayName: $disp_name" >> alta_usuario.ldif
          #La primera vez que se ejecute, el uidNumber debe ser 2000 (debemos escribirlo a mano).
          #Una vez hecho, la funcion generar_uid nos devolvera el ultimo uid sumandole uno(uid + 1)
          echo "uidNumber:  $(generar_uid)" >> alta_usuario.ldif
          echo "gidNumber: 10000" >> alta_usuario.ldif
          echo "userPassword: $contrasenia" >> alta_usuario.ldif
          echo "gecos: $disp_name" >> alta_usuario.ldif
          echo "loginShell: /home/bash" >> alta_usuario.ldif
          echo "homeDirectory: /home/$uid1" >> alta_usuario.ldif
          echo "shadowExpire: -1" >> alta_usuario.ldif
          echo "shadowFlag: 0" >> alta_usuario.ldif
          echo "shadowWarning: 7" >> alta_usuario.ldif
          echo "shadowMin: 8" >> alta_usuario.ldif
          echo "shadowMax: 999999" >> alta_usuario.ldif
          echo "shadowLastChange: 10877" >> alta_usuario.ldif
          echo "mail: $nombre_m.$apellido_m@$dc1.$dc2" >> alta_usuario.ldif
          echo "postalCode: 29000" >> alta_usuario.ldif
          echo "o: $dc1" >> alta_usuario.ldif
          echo "initials: `echo $nombre | cut -c1``echo $apellido | cut -c1`" >> alta_usuario.ldif
          #Comentar la siguiente linea cuando se esten haciendo pruebas y descomentar la de despues
          ldapadd -x -D cn=admin,dc=$dc1,dc=$dc2 -W -f alta_usuario.ldif > /dev/nul && echo -e "\nSe ha dado de alta correctamente el usuario \"$uid1\"" \ || echo -e "\n$(error) No se ha dado de alta el usuario \"$uid1\""
          #read
          rm -f alta_usuario.ldif
        fi
      fi
    fi
  fi
fi
