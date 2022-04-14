#!/bin/bash

function ayuda() {
    echo "El script se encarga de obtener el producto mas vendido de cada sucursal (por semana), "
    echo "el total recaudado por cada sucursal y por ultimo limpiar los archivos para la semana siguiente"
    echo ""
    echo "Recibe como parametro el directorio donde se encuentara la informacion de las sucursales"
    echo ""
    echo "  -s Directorio donde se generara un archivo de log con la informacion generada por el script,"
    echo "     si no se informa se generara el mismo directorio donde se encuentra el script."
    echo ""
    echo "  -k si este parametro esta presente, se debe generar un backup en formato .zip"
    echo "     que contenga todos los archivos procesados."  
    echo ""
    echo "Modo de ejecución:"
    echo "./script.sh -e archivosSucursales -s ./salida"
    echo "./script.sh -e entradas/archivos/ -k"
}

archivoSalida=""
declare -A ventasPorProductos # {CocaCola = 10, Fanta: 54, Sprite: 40}
declare -A totalSucursal # {Sucursal1: 2000, Sucursal2: 4900}
declare -a sucursales
declare -a productos

function formateoNombre(){
    dia=$(date +%d)
    mes=$(date +%m)
    anio=$(date +%y)
    hora=$(date +%I)
    minuto=$(date +%M)
    segundo=$(date +%S)
    archivoSalida="$dia-$mes-$anio-$hora-$minuto-$segundo"
}


function productoMasVendido(){

    declare -a ventas

    for i in ${!ventasPorProductos[@]}
    do 
        ventas+=(${ventasPorProductos[$i]})
        
    done
    mayorVenta=0

    for ((i=0; i <${#ventas[@]}; i++))
    do 
        numero=${ventas[$i]}

        if [ $numero -gt $mayorVenta ]; then
            mayorVenta=$numero
        fi
    done
    
    echo "$mayorVenta"

   for i in ${!ventasPorProductos[@]}
   do
      
        valor=${ventasPorProductos[$i]}
        if [ $valor -eq $mayorVenta ]; then 
        echo "El producto mas vendido es ${i} con un total de ventas de: ${valor}" >> "$archivoSalida.log"
        fi

        ventasPorProductos[$i]=0
   done

}

function recaudadoPorSucursal(){
    echo "Total recaudado: $1"
}

options=$(getopt -o e:s:h:k --l help,entrada:,salida: -- "$@" 2> /dev/null)
if [ "$?" != "0" ]
then
    echo 'opciones incorrectas'
    exit 1
fi


eval set -- "$options"
while true
do
    case "$1" in
        -e | --entrada)
            entrada="$2"
            shift 2

            if [ ! -d "$entrada" ]
            then
                echo "$entrada no existe o no es un directorio"
                ayuda
                exit 1
            elif [ ! -r "$entrada" ]
            then
                echo "$entrada no tiene permisos de lectura"
                exit 1
            fi
            ;;

        -s | --salida) 
            salida="$2"
            shift 2

            if [ ! -d "$salida" ]
            then
                echo "$salida no existe o no es un directorio"
                ayuda
                exit 1
            else
                formateoNombre
                touch "$salida/$archivoSalida.log"
            fi
            ;;
        
        -h | --help)
            ayuda
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "error"
            exit 1
            ;;
    esac
done




haySalida=1
if [[ -z $salida ]]
then 
    haySalida=0
    echo "No hay parametro"
    formateoNombre
    touch "$archivoSalida.log"   
fi

path=$entrada
cd $path 

for sucursal in $(ls)
do 
    sucursales+=($sucursal)
    if [ -d "$sucursal" ]
    then
        cd $sucursal
        totalRecaudado=0
        for dia in $(ls)
        do 
            primeraLinea=1 
            for linea in $(cat "$dia")
            do 
                if [[ $primeraLinea != 1 ]]
                then 
                    producto=$(echo "$linea" | cut -d "|" -f 1)
                    ventas=$(echo "$linea" | cut -d "|" -f 2)
                    recaudado=$(echo "$linea" | cut -d "|" -f 3)
                    totalRecaudado=$((totalRecaudado + $recaudado))
                    ventasPorProductos[$producto]=$((ventasPorProductos[$producto]+$ventas))                            
                fi
                primeraLinea=0
            done
        done 
        totalSucursal[$sucursal]=$totalRecaudado

        ## Sin parametro de salida, me muevo hasta la raiz
        if [ $haySalida -eq 0 ]; then
            cd ../..
            echo "" >> "$archivoSalida.log"
            echo "Sucursal N°: $(echo "$sucursal" | cut -d "l" -f 2)"  >> "$archivoSalida.log"
            recaudadoPorSucursal ${totalSucursal[$sucursal]} >> "$archivoSalida.log"
            productoMasVendido
            cd $entrada
        else  ## con parametro de salida, me muevo hasta el directorio
            cd ../..
            cd $salida
            echo "" >> "$archivoSalida.log"
            echo "Sucursal N°: $(echo "$sucursal" | cut -d "l" -f 2)"  >> "$archivoSalida.log"
            recaudadoPorSucursal ${totalSucursal[$sucursal]} >> "$archivoSalida.log"
            productoMasVendido
            cd ../$entrada
        fi
     fi
done
