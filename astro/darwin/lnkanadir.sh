#!/bin/zsh

anadir=/Users/yyoshida/Dropbox/Analysis
obsdir=/Users/yyoshida/SpiritDrive/Study/Observation
astdir=/Users/yyoshida/SpiritDrive/Study/Astro
logdir=/Users/yyoshida/LogLinks
bibdir=/Users/yyoshida/BibDesk
obj=(1A1118-61 4U0114+65 4U1538-522 4U1626-67 4U1700-37 4U1907+097 4U1909+07 4U1954+31 4U2206+54 A0535+262 CenX-3 CepX-4 Crab GROJ1008-57 GX1+4 GX301-2 GX304-1 HerX-1 IGRJ16393-4643 OAO1657-415 Pulsar VelaX-1 XPer)


[ -e ${bibdir} ]||mkdir ${bibdir}
cd ${bibdir}
for src in ${obj} ;do
    [ -e ${src} ]||ln -sf ${anadir}/${src}/paper ${src}
done

for obs in BeppoSAX Hitomi RXTE Suzaku ;do
    [ -e ${obs} ]||ln -sf ${obsdir}/${obs}/paper ${obs}
done

[ -e Astro ]||ln -sf ${astdir}/paper Astro

[ -e ${logdir} ]||mkdir ${logdir}
cd ${logdir}
for src in ${obj} FiniteLightSpeedEffect Pulsar;do
    [ -e ${src} ]||ln -sf ${anadir}/${src}/log ${src}
done

    
    
