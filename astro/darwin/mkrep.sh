#!/bin/zsh

###########################################################################
## Value
###########################################################################
ANALYSIS_DIR=$HOME/Dropbox/astro
TEMPLATE_DIR=${ANALYSIS_DIR}/Pulsar/report/template
STYTEXFILE=${TEMPLATE_DIR}/pagestyle.tex
TMPTEXFILE=${TEMPLATE_DIR}/template.tex
FIGTEXFILE=${TEMPLATE_DIR}/figure.tex
AUTHOR='Y.Yoshida'
SCRIPTFILE=$0
[ -L ${SCRIPTFILE} ] && SCRIPTFILE=$(readlink $0)
SCRIPTNAME=$(basename ${SCRIPTFILE%.*})


###########################################################################
## Function
###########################################################################
usage(){
    echo "Analysis report maker written by ${AUTHOR}"
    echo "USAGE"
    echo "  ${SCRIPTNAME} [OPTION] <OBJECT> <IDNUM>"
    echo ""
    echo "OBJECT"
    echo "  al:  for All"
    echo "  az:  for A0535+262"
    echo "  cg:  for CygX-3"
    echo "  cn:  for CenX-3"
    echo "  cp:  for CepX-4"
    echo "  ex:  for EXO2030+375"
    echo "  fe:  for 4U1954+31"
    echo "  ff:  for 4U1538-522"
    echo "  fs:  for 4U1822-37"
    echo "  ft:  for 4U2206+54"
    echo "  fu:  for 4U1626-67"  
    echo "  fz:  for 4U0114+65"
    echo "  gx:  for GX1+4"
    echo "  go:  for GX301-2"
    echo "  gf:  for GX304-1"
    echo "  he:  for HerX-1"
    echo "  ig:  for IGRJ16393-4643"
    echo "  jo:  for GROJ1008-57"
    echo "  lf:  for LMCX-4"
    echo "  oa:  for 1A1118-61"
    echo "  os:  for OAO1657-415"
    echo "  so:  for SMCX-1"
    echo "  vl:  for VelaX-1"
    echo "  xp:  for XPer"
    echo "  zn:  for 4U1909+07"
    echo "  zs:  for 4U1907+097"
    echo ""
    echo "OPTION"
    echo "  -h)  Show this help script"
    echo "  -s)  snapshot"
    echo "  -f)  Make TeX file for figure"
    exit 0
}


issue(){
    local outfile=$1
    local object=$2
    local type=$3
    local name=$4
    local number=$5

    cat ${TMPTEXFILE} | sed -e "s%(STYLE)%${STYTEXFILE}%g; s%(OBJECT)%${object}%g; s%(TYPE)%${type}%; s%(NAME)%${name}%g; s%(NUMBER)%${number}%g" > ${outfile}
}

snapshot(){
    local obj=$1
    local num=$2
    local dir=$3
    local src=$4

    if [ -e ${src} ];then
        [ -d ${dir}/edition ]||mkdir ${dir}/edition
        for v in `seq -f '%5.1f' 1.0 0.1 100.0` ;do
            outfile=${dir}/edition/${obj}-${num}-v${v}.pdf
            if [ ! -e ${outfile} ];then
                break
            fi
        done
        cp ${in_src} ${outfile}
        echo "`basename ${outfile}` is issued"
        return 0
    else
        echo "`basename ${srcfile}` is not found !!"
        return 1
    fi
}

###########################################################################
## OPTION
###########################################################################
GETOPT=`getopt -q -o husf -l usage,help,snapshot,figure -- "$@"` ; [ $? != 0 ] && usage

eval set -- "$GETOPT"

FLG_S=0
FLG_F=0
FLG_I=1

while true ;do
    case $1 in
        -u|-h|--usage|--help) usage ;;
        -s|--snapshot) FLG_S=1; shift ;;
        -f|--figure)   FLG_F=1; shift ;;
        --) shift; break ;;
        *) usage ;;
    esac
done


###########################################################################
## Main
###########################################################################
if [ $# -ne 2 ];then
    usage
else
    obj=$1
    num=$2
    case ${obj} in
        al) objdir=Pulsar
            type=APXP
            name=AL ;;
        az) objdir=A0535+262
            type=APXP
            name=AZ ;;
        cn) objdir=CenX-3
            type=APXP
            name=CN ;;
        cg) objdir=CygX-3
            type=PLZM
            name=CY ;;
        cp) objdir=CepX-4
            type=APXP
            name=CP ;;
        ex) objdir=EXO2030+375
            type=APXP
            name=EX ;;
        fe) objdir=4U1954+31
            type=APXP
            name=FE ;;
        ff) objdir=4U1538-522
            type=APXP
            name=FF ;;
        fs) objdir=4U1822-37
            type=APXP
            name=FS ;;
        ft) objdir=4U2206+54
            type=APXP
            name=FT ;;
        fu) objdir=4U1626-67
            type=APXP
            name=FU ;;
        fz) objdir=4U0114+65
            type=APXP
            name=FZ ;;
        gf) objdir=GX304-1
            type=APXP
            name=GF ;;
        go) objdir=GX301-2
            type=APXP
            name=GO ;;
        gx) objdir=GX1+4
            type=APXP
            name=GX ;;
        he) objdir=HerX-1
            type=APXP
            name=HE ;;
        ig) objdir=IGRJ16393-4643
            type=APXP
            name=IG ;;
        jo) objdir=GROJ1008-57
            type=APXP
            name=JO ;;
        lf) objdir=LMCX-4
            type=APXP
            name=LF ;;
        oa) objdir=1A1118-61
            type=APXP
            name=OA ;;
        os) objdir=OAO1657-415
            type=APXP
            name=OS ;;
        so) objdir=SMCX-1
            type=APXP
            name=SO ;;
        vl) objdir=VelaX-1
            type=APXP
            name=VL ;;
        xp) objdir=XPer
            type=APXP
            name=XP ;;
        zn) objdir=4U1909+07
            type=APXP
            name=ZN ;;
        zs) objdir=4U1907+097
            type=APXP
            name=ZS ;;
        *) usage ;;
    esac

    out_dir=${ANALYSIS_DIR}/${objdir}/report/${type}-${name}-${num}

    if [ ${FLG_S} -eq 1 ];then
        srcfile=${out_dir}/${obj}-${num}.pdf
        snapshot ${obj} ${num} ${out_dir} ${srcfile}
    elif [ ${FLG_F} -eq 1 ];then
        pdfflnum=$(ls -1 ${out_dir}/fig|sed -n '/.pdf/p'|wc -l) #; echo ${pdfflnum} 
        epsflnum=$(ls -1 ${out_dir}/fig|sed -n '/.*ps/p'|wc -l) #; echo ${epsflnum}
        if [ ${pdfflnum} -ne 0 ]||[ ${epsflnum} -ne 0 ];then
            cd ${out_dir}
            figset=()
            [ ${pdfflnum} -ne 0 ] && figset+=($(ls ./fig/*.pdf))
            [ ${epsflnum} -ne 0 ] && figset+=($(ls ./fig/*.*ps))
            for fig in ${figset};do
                fig_dir=${fig%.*}
                if [ -d ${fig_dir} ];then
                    mv -f ${fig} ${fig_dir}
                else
                    mkdir ${fig_dir}
                    mv -f ${fig} ${fig_dir}
                    fig_tex=${fig_dir}/$(basename ${fig_dir}).tex
                    caption=$(basename ${fig_dir}|sed 's/\_/-/g')
                    cat ${FIGTEXFILE} | sed "s%(FILE)%${fig_dir}\/$(basename ${fig})%g; s%(CAPTION)%${caption}%g; s%(NAME)%${fig_dir}%g" > ${fig_tex}
                    echo "\input{${fig_tex%.tex}}"
                fi
            done
		fi
    else
        outfile=${out_dir}/${obj}-${num}.tex
        if [ -e ${outfile} ];then
            echo "Report ID:${type}-${name}-${num} already exist !!"
            echo -n "Overwrite ?? [Y/n] >> "
            while read answer ;do
                case ${answer} in
                    y|Y|yes|Yes|YES)
                        rm -f ${outfile}; break ;;
                    n|N| no| No| NO)
                        FLG_I=0; break ;;
                    *) echo -n "Overwrite ?? [Y/n] >> " ;;
                esac
            done
        fi
        if [ ${FLG_I} -eq 1 ];then
            [ -d ${out_dir} ]||mkdir -p ${out_dir}/fig ${out_dir}/edition
            issue ${outfile} ${obj} ${type} ${name} ${num}
            echo "${SCRIPTNAME} edited Report ID:${type}-${name}-${num}."
        fi
    fi
fi


#EOF#
