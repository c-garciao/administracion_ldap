#!/bin/bash
#Script de modificacion de usuarios. Creado por Carlos Garcia Oliva
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
      echo -e "------Escoja un usuario a \e[93mModificar\e[0m:------"
      cat usuarios.tmp
      echo "-------------------------------------"
      read usuario
      if [ -z $usuario ]
      then
        echo "$(error) No ha introducido ningun nombre"
        break #read
      else
        existe=`cat usuarios.tmp | grep -w $usuario | wc -l`
        if [ $existe -ne 1 ]
        then
          echo -e "$(error) No existe el usuario \"$usuario\".Introduzca un usuario de la la lista"
          break #read
        else
          #Obtenemos la ud Organizativa en la que esta el usuario
          ud_org=`slapcat | grep -E "uid=$usuario" | cut -d"=" -f3 | cut -d"," -f1`
          #Guardamos el resultado de la funcion en una variable (shell NO devuelve string, solo enteros o codigos de error [exit codes])
          #modificar
          #opc=$(modificar)
          #echo "Voy despues de la funcion"
          clear
          echo -e "Escoja el atributo a cambiar:\n\t1)GivenName\n\t2)Email(solo direccion, sin @)\n\t3)CP\n\t4)Iniciales\n\t5)Grupo"
          read opcion
          if [ -z $opcion ]
          then
            echo "$(error) No ha escogido ninguna opcion"
            break #read
          else
            case $opcion in
              1)
              tipo="nombre"
              opc="givenName"
              ;;
              2)
              tipo="correo electronico"
              opc="mail"
              ;;
              3)
              tipo="codigo postal"
              opc="postalCode"
              ;;
              4)
              tipo="iniciales"
              opc="initials"
              ;;
              5)
              tipo="grupo"
              opc="gidNumber"
              ;;
              *)
              echo -e "$(error) La opcion $opcion no es valida"
              break #read
              ;;
            esac
            if [ "$opc" == "gidNumber" ]
            then
              ldapsearch -xLLL -b "dc=$dc1,dc=$dc2" "(objectClass=posixGroup)" | grep -E  "gidNumber|cn:" > grupos.tmp
              echo -e "------Grupos \e[93mdisponibles\e[0m:------"
              #Imprimimos las lineas impares (%2==1) con awk. Son las lineas que contienen el gid. Nos quedamos solo con el numero (cut -d":")
              cat grupos.tmp
              echo "-------------------------------------"
              echo -e  "Esocoja un grupo (escriba solo el \e[43mgid\e[0m)"
            fi
            echo -n "Escoja el nuevo valor de $tipo:"
            read nuevo
            if [ -z $nuevo ]
            then
              echo "$(error) No puede dejar vacio el campo "$tipo""
              break #read
            else
              if [ "$opc" == "mail" ]
              then
                if [[ "$nuevo" =~ ['!@#$%^&*()_+'] ]]
                then
                  echo -e "$(error) La direccion de correo solo puede contener caracteres alfanumericos (el dominio ya se ha proporcionado y es $dc1.$dc2)"
                  break
                else
                  nuevo="$nuevo@$dc1.$dc2"
                fi
              elif [ "$opc" == "postalCode" ]
              then
                if ! [[ "$nuevo" =~ ^[0-9]+$ ]]
                then
                  echo -e "$(error) El codigo postal solo puede contenter numeros"
                  break
                fi
              elif [ "$opc" == "initials" ]
              then
                #Contamos el numero de caracteres (wc -m). De no usar el modificador -e en el echo, nos contara siempre uno mas (retorno de carro)
                numero_iniciales=`echo -n $nuevo | wc -m`
                #Nos aseguramos que el usuario introduzca solo dos caracteres y ambos sean letras
                if ! [[ "$nuevo" =~ ^[a-zA-Z]+$ ]] || [[ "$nuevo" =~ ['!@#$%^&*()_+'] ]]
                then
                  echo -e "$(error) La iniciales no pueden contener numeros o caracteres NO alfanumericos"
                  break #read
                fi
                if [ $numero_iniciales -ne 2 ]
                then
                  echo -e "$(error) Solo puden ser dos iniciales"
                  break #read
                else
                  #Si todo es correcto, convertimos a mayusculas las iniciales
                  nuevo="${nuevo^^}"
                fi
              elif [ "$opc" == "gidNumber" ]
              then
                if ! [[ "$nuevo" =~ ^[0-9]+$ ]]
                then
                  echo -e "$(error) El GID solo contiene numeros"
                  break
                fi
              fi
              echo "dn: uid=$usuario,ou=$ud_org,dc=$dc1,dc=$dc2" > modificar_usuario.ldif
              echo "changetype: modify" >> modificar_usuario.ldif
              echo "replace: $opc" >> modificar_usuario.ldif
              echo "$opc: $nuevo"  >> modificar_usuario.ldif
              ldapmodify -x -D cn=admin,dc=$dc1,dc=$dc2 -W -f modificar_usuario.ldif > /dev/nul && echo -e "\nSe ha modificado correctamente el atributo \"$tipo\" del usuario  \"$usuario\"" \ || echo -e "$(error) No se ha modificado el atributo \"$tipo\" del usuario \"$usuario\""
              #read e
              rm -f usuarios.tmp
              rm -f modificar_usuario.ldif
              rm -f grupos.tmp
              echo -e "\nDesea modificar otro atributo (S/N)"
              read modificar
              if [ -z $modificar ]
              then
                echo "$(error) No ha escogido ninguna opcion"
                break #read
              elif [ $modificar == "N" -o $modificar == "n" ]
              then
                clear
                break
              elif ! [[ "$modificar" == "S" ]] #|| ! [[ "$modificar" == "s" ]] #quitar s minuscula
              then
                echo "$(error) Opcion no valida"
                break #read
              fi
            fi
          fi
        fi
      fi
    done
  fi
fi
