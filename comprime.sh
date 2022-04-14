#!/bin/bash

archivoSalida=""

function formateoNombre(){
    dia=$(date +%d)
    mes=$(date +%m)
    anio=$(date +%y)
    hora=$(date +%I)
    minuto=$(date +%M)
    segundo=$(date +%S)
    archivoSalida="$dia-$mes-$anio-$hora-$minuto-$segundo"
}
formateoNombre
directorioComprimido="$archivoSalida.zip"
echo $directorioComprimido
zip -r 14-04-22-02-18-41.zip /Sucursales
