#!/bin/bash
red () {
	arch="$USER-$(date +'%d-%m-%y').conf"
	cat template-dhcp.conf > $arch
        read -p "Crear red para dar direcciones IP. EJ: 192.168.1.0 " red
        if [ "$red" != "" ]; then
                sudo sed -i "s/cambiar_red/$red/" $arch
        fi
        read -p "Añadir mascara de red de: $red EJ: 255.255.255.0 (Dejar vacío si no quieres configurar este paso) " mask
       	if [ "$mask" != "" ]; then
		sudo sed -i "s/cambiar_mask/$mask/" $arch
	fi
	read -p "Añadir inicio de rango. EJ: 192.168.1.1 (Dejar vacío si no quieres configurar este paso) " inicio
	if [ "$inicio" != "" ]; then
		sudo sed -i "s/#range cambiar_inicio cambiar_final;/range $inicio cambiar_final;/" $arch
	fi
	read -p "Añadir final de rango. EJ: 192.168.1.10 (Dejar vacío si no quieres configurar este paso) " final
	if [ "$final" != "" ]; then
		sudo sed -i "s/cambiar_final/$final/" $arch
	fi
        read -p "Añadir servidores DNS. EJ: 8.8.8.8 (Dejar vacío si no quieres configurar este paso) " dns
	if [ "$dns" != "" ]; then
		sudo sed -i "s/#option domain-name-servers cambiar_dns;/option domain-name-servers $dns;/" $arch
	fi
        read -p "Añadir nombre de dominio. EJ: servidor.com (Dejar vacío si no quieres configurar este paso) " dom
        if [ "$dom" != "" ]; then
		sudo sed -i "s/#option domain-name cambiar_nombredominio;/option domain-name \"$dom\";/" $arch
	fi
	read -p "Añadir gateway. Ej: 192.168.1.1 (Dejar vacío si no quieres configurar este paso) " gateway
	if [ "$gateway" != "" ]; then
		sudo sed -i "s/#option routers cambiar_gateway;/option routers $gateway;/" $arch
	fi
	read -p "Añadir dirección broadcast: EJ: 192.168.1.255 (Dejar vacío si no quieres configurar este paso) " broad
	if [ "$broad" != "" ]; then
		sudo sed -i "s/#option broadcast-address cambiar_broadcast;/option broadcast-address $broad;/" $arch
	fi
	read -p "Configurar default-lease-time: EJ: 86400 (Dejar vacío si no quieres configurar este paso) " default
	if [ "$default" != "" ]; then
		sudo sed -i "s/#default-lease-time cambiar-lease;/default-lease-time $default;/" $arch
	fi
	read -p "Configurar max-lease-time: EJ: 168205 (Dejar vacío si no quieres configurar este paso) " max
	if [ "$max" != "" ]; then
		sudo sed -i "s/#max-lease-time cambiar-max;/max-lease-time $max;/" $arch
	fi
	sudo cat $arch >> /etc/dhcp/dhcpd.conf
}

hosts () {
	arch=hosts_$USER.conf
        cat template-host.conf > $arch
        read -p "Añadir host con dirección fija: [Y/n] " res
        if [ "$res" != "" ]; then
                read -p "Nombre del host fijo: " host
                sed -i "s/host cambiar_nombre/host $host/" $arch
                read -p "Direccion MAC: " mac
                sed -i "s/#hardware ethernet cambiar_eth;/hardware ethernet $mac;/" $arch
                read -p "Configurar direccion fija: " fixed
                sed -i "s/#fixed-address cambiar_fixed;/fixed-address $fixed/;" $arch
                read -p "Configurar DNS: " dns
                sed -i "s/#option domain-name-servers cambiar_dns;/option domain-name-servers $dns;/" $arch
                read -p "Configurar direccion gateway: " router
                sed -i "s/#option routers cambiar_routers;/option routers $router;/" $arch
                sed -i "/group {/r $arch" group-hosts.txt
        fi
}
add () {
	cat group.conf > group-hosts.txt
	cat group-hosts.txt
}
insert () {
	cat group-hosts.txt
	sudo cat group-hosts.txt >> /etc/dhcp/dhcpd.conf
}

menu () {
	while true
	do
		select accion in addhostToGroup addgroup insertINTODHCP salir
		do
			case $accion in
				"addhostToGroup") hosts;;
				"addgroup") add;;
				"insertINTODHCP") insert;;
				"salir") return 0;;
			esac
		done
	done

}

read -p "Quieres instalar isc-dhcp-server [Y/n] " res
if [ $res == "Y" ]; then
	sudo apt install isc-dhcp-server
	contarIface=$(ip a | cut -d " " -f1 |  sed '/^\s*$/d' | wc -l)
	if [ $contarIface -gt 2 ]; then
		ip a
		read -p "Tienes más de dos interfaces de red, elige la interfaz de red a utilizar /etc/default/isc-dhcp-server EJ:enp0s8 " conf
		sudo sed -i "s/INTERFACESv4=\"\"/INTERFACESv4=\"$conf\"/"  /etc/default/isc-dhcp-server
		cat /etc/default/isc-dhcp-server | grep "INTERFACESv4"
		red
		menu
	fi
fi



