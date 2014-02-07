#!/bin/bash

#Eliminamos los ficheros auxiliares que podrían haberse
#quedado abandonados de ejecuciones previas
rm eventos.txt 2>/dev/null
rm todosloseventos.txt.gz 2>/dev/null
rm todoslosusuarios.txt 2>/dev/null
rm usuarios.txt 2>/dev/null
rm listaeventos_raw.txt 2>/dev/null

echo "[$(date +%R)] Generando lista de eventos..."
#Extraemos todos los logs de un mes
#Esto es una BARBARIDAD, ocupa mucho espacio y genera mucha carga
#Lo suyo sería reescribirlo para generar el CSV iterando los logs de cada día
for dir in $(ls /path/to/log/repository/year/month)
do
        zcat /path/to/log/repository/year/month/$dir/windows/*.gz >> todosloseventos.txt
done

#Como el fichero será gigantesco lo comprimimos
echo "[$(date +%R)] Comprimiendo eventos..."
gzip todosloseventos.txt

#Parseamos los eventos y generamos un fichero temporal formado únicamente por sus títulos
#Esta información aparece en el decimotercer campo delimitado por #
#El título tendrá una forma del tipo #011Nombre_del_evento.
#Aplicamos las operaciones necesarias para extraer el nombre y eliminar el 011 del inicio
zcat todosloseventos.txt.gz | cut -d "#" -f14 | cut -d "." -f1 | sed 's/011//g' >> listaeventos_raw.txt
echo "[$(date +%R)] $(cat listaeventos_raw.txt | wc -l) eventos totales. Identificando eventos unicos..."

#Generamos una lista de eventos unicos y eliminamos el fichero en bruto
cat listaeventos_raw.txt | sort | uniq >> eventos.txt
rm listaeventos_raw.txt 2>/dev/null
echo "[$(date +%R)] Hecho, $(cat eventos.txt | wc -l) eventos unicos identificados"

#Extraemos los nombres de usuario mediante una regex y construimos un fichero con ellos
#Estos tienen la forma de XUnnnn para usuarios y XAnnnn para administradores
zcat todosloseventos.txt.gz | grep -o 'X[A|U][0-9]\{4\}' >> todoslosusuarios.txt
echo "[$(date +%R)] $(cat todoslosusuarios.txt | wc -l) usuarios extraidos de los logs."

#Eliminamos los duplicados y eliminamos el fichero temporal
cat todoslosusuarios.txt | sort | uniq >> usuarios.txt
rm todoslosusuarios.txt 2>/dev/null
echo "[$(date +%R)] $(cat usuarios.txt | wc -l) usuarios unicos identificados"

#Empezamos a generar el CSV
#Como esto está hecho del tirón en realidad lo mostramos por pantalla en lugar de generar el fichero
#Pendiente de implementar
#En primer lugar creamos una fila con todos los nombres de usuario identificados
echo "[$(date +%R)] Generando fichero .csv"
echo -n " ;"
for usu in $(cat usuarios.txt)
	do
        echo -n "$usu; "
	done
echo ""

#Cambiamos el separador de campo a salto de linea para poder recorrer la lista de eventos con un for
oldIFS=$IFS
IFS=$'\n'
for evento in $(cat eventos.txt)
	do
        #Extraemos del log en bruto solo los eventos de este tipo
        zcat todosloseventos.txt.gz | grep $evento >> temporal.txt
        echo -n "$evento; "
        #Revertimos temporalmente el cambio de separador de campo
        IFS=$oldIFS
        for usuario in $(cat usuarios.txt)
			do
                #Imprimimos el numero de ocurrencias de cada evento por cada usuario
                echo -n "$(cat temporal.txt | grep $usuario | wc -l); "
			done
        oldIFS=$IFS
        IFS=$'\n'
        echo ""
        #Eliminamos el temporal de esta iteracion
        rm temporal.txt
	done
echo ""

#Finalizamos
echo "[$(date +%R)] Finalizado"

#Eliminamos los ficheros implicados
rm todosloseventos.txt.gz 2>/dev/null
rm usuarios.txt 2>/dev/null

#Y listo
IFS=$oldIFS
#EOF
