from __future__ import division
from numpy import linspace, loadtxt, ones, convolve
from ROOT import *
from collections import OrderedDict
import time
import os, sys
import ConfigParser
import numpy 
import math


data = loadtxt("3bandlc_clean.qdp")

t = data[:,0]
low = data[:,1]
dlow = data[:,2]
med = data[:,3]
dmed = data[:,4]
high = data[:,5]
dhigh = data[:,6]
hr1 = data[:,7]
dhr1 = data[:,8]
hr2 = data[:,9]
dhr2 = data[:,10]

###



LCTZERO=0
START=55050-LCTZERO
STOP=57410-LCTZERO


#dRESULT={}
dRESULT = OrderedDict()

## LC low
dPARAM={}
dPARAM["num"]=0
dPARAM["NAME"]="low"
dPARAM["YLABEL"]="#splitline{2-4 keV}{ph s^{-1} cm^{-2}}"
dPARAM["axis_min"]=0.0
dPARAM["axis_max"]=5.0
dPARAM["logy"]=0
dRESULT["%s"%(dPARAM["NAME"])]=dPARAM
print dRESULT.keys()

## LC med
dPARAM={}
dPARAM["num"]=1
dPARAM["NAME"]="med"
dPARAM["YLABEL"]="#splitline{4-10 keV}{ph s^{-1} cm^{-2}}"
dPARAM["axis_min"]=0.0
dPARAM["axis_max"]=2.0
dPARAM["logy"]=0
dRESULT["%s"%(dPARAM["NAME"])]=dPARAM
print dRESULT.keys()

## LC high
dPARAM={}
dPARAM["num"]=2
dPARAM["NAME"]="high"
dPARAM["YLABEL"]="#splitline{10-20 keV}{ph s^{-1} cm^{-2}}"
dPARAM["axis_min"]=0.0
dPARAM["axis_max"]=0.6
dPARAM["logy"]=0
dRESULT["%s"%(dPARAM["NAME"])]=dPARAM
print dRESULT.keys()

## HR low
dPARAM={}
dPARAM["num"]=3
dPARAM["NAME"]="hr1"
dPARAM["YLABEL"]="HR low"
dPARAM["axis_min"]=0.0
dPARAM["axis_max"]=1.5
dPARAM["logy"]=0
dRESULT["%s"%(dPARAM["NAME"])]=dPARAM
print dRESULT.keys()

## HR high
dPARAM={}
dPARAM["num"]=4
dPARAM["NAME"]="hr2"
dPARAM["YLABEL"]="HR high"
dPARAM["axis_min"]=0.0
dPARAM["axis_max"]=1.0
dPARAM["logy"]=0
dRESULT["%s"%(dPARAM["NAME"])]=dPARAM
print dRESULT.keys()


dGRAPH_hard={}
dGRAPH_soft={}

for PAR in dRESULT.keys():
  dGRAPH_hard[PAR] = TGraphErrors(len(t))
  dGRAPH_hard[PAR].SetName("%s"%(PAR))
  dGRAPH_soft[PAR] = TGraphErrors(len(t))
  dGRAPH_soft[PAR].SetName("%s"%(PAR))
  

index_soft = 0
index_hard = 0
for i in range(0, len(t)):
  if hr1[i] < 0.43:
    dGRAPH_soft["low"].SetPoint(index_soft, t[i], low[i])
    dGRAPH_soft["low"].SetPointError(index_soft, 0, dlow[i])
    dGRAPH_soft["med"].SetPoint(index_soft, t[i], med[i])
    dGRAPH_soft["med"].SetPointError(index_soft, 0, dmed[i])
    dGRAPH_soft["high"].SetPoint(index_soft, t[i], high[i])
    dGRAPH_soft["high"].SetPointError(index_soft, 0, dhigh[i])
    dGRAPH_soft["hr1"].SetPoint(index_soft, t[i], hr1[i])
    dGRAPH_soft["hr1"].SetPointError(index_soft, 0, dhr1[i])
    dGRAPH_soft["hr2"].SetPoint(index_soft, t[i], hr2[i])
    dGRAPH_soft["hr2"].SetPointError(index_soft, 0, dhr2[i])   
    index_soft+=1
    
  elif hr1[i] > 0.48:
    dGRAPH_hard["low"].SetPoint(index_hard, t[i], low[i])
    dGRAPH_hard["low"].SetPointError(index_hard, 0, dlow[i])
    dGRAPH_hard["med"].SetPoint(index_hard, t[i], med[i])
    dGRAPH_hard["med"].SetPointError(index_hard, 0, dmed[i])
    dGRAPH_hard["high"].SetPoint(index_hard, t[i], high[i])
    dGRAPH_hard["high"].SetPointError(index_hard, 0, dhigh[i])
    dGRAPH_hard["hr1"].SetPoint(index_hard, t[i], hr1[i])
    dGRAPH_hard["hr1"].SetPointError(index_hard, 0, dhr1[i])
    dGRAPH_hard["hr2"].SetPoint(index_hard, t[i], hr2[i])
    dGRAPH_hard["hr2"].SetPointError(index_hard, 0, dhr2[i])
    print t[i]-0.5, t[i]+0.5
    index_hard+=1


for PAR in dRESULT.keys():
  dGRAPH_soft[PAR].GetXaxis().SetLimits(START,STOP)
  dGRAPH_soft[PAR].GetXaxis().SetTitle("MJD")
  dGRAPH_soft[PAR].GetYaxis().SetTitle("%s"%(dRESULT[PAR]["YLABEL"]))
  dGRAPH_soft[PAR].SetMinimum(dRESULT[PAR]["axis_min"])
  dGRAPH_soft[PAR].SetMaximum(dRESULT[PAR]["axis_max"])
  dGRAPH_hard[PAR].GetXaxis().SetLimits(START,STOP)
  dGRAPH_hard[PAR].GetXaxis().SetTitle("MJD")
  dGRAPH_hard[PAR].GetYaxis().SetTitle("%s"%(dRESULT[PAR]["YLABEL"]))
  dGRAPH_hard[PAR].SetMinimum(dRESULT[PAR]["axis_min"])
  dGRAPH_hard[PAR].SetMaximum(dRESULT[PAR]["axis_max"])
    

###########


MK=[[55050-LCTZERO,55050.01-LCTZERO]]
MKLST={}

SPECMJD_DICT={}
for PAR in dRESULT.keys():
  MIN=dRESULT[PAR]["axis_min"]
  MAX=dRESULT[PAR]["axis_max"]
  VAR=(MIN+MAX)*0.5
  VARERR=(MAX-MIN)*0.5
#      print MIN, MAX
  tmpSPECMJD=TGraphErrors(9)
  index=0
  for LINE in MK:
    tmpSPECMJD.SetPoint(index, (LINE[1]+LINE[0])*0.5,  VAR)
    tmpSPECMJD.SetPointError(index, (LINE[1]-LINE[0])*0.5, VARERR )
    index+=1  
  tmpSPECMJD.SetLineColor(15)
  tmpSPECMJD.SetLineWidth(2)
  tmpSPECMJD.SetLineStyle(3)
  tmpSPECMJD.SetName("SPECMJD_%s"%(PAR))
  tmpSPECMJD.GetXaxis().SetLimits(START,STOP)
  tmpSPECMJD.GetXaxis().SetTitle("MJD")
  tmpSPECMJD.GetYaxis().SetTitle("%s"%(dRESULT[PAR]["YLABEL"]))
  tmpSPECMJD.SetMinimum(dRESULT[PAR]["axis_min"])
  tmpSPECMJD.SetMaximum(dRESULT[PAR]["axis_max"])
  tmpSPECMJD.SetTitle("")
  tmpSPECMJD.GetXaxis().SetNdivisions(510);
  tmpSPECMJD.GetYaxis().SetNdivisions(505);
  tmpSPECMJD.GetYaxis().SetTitleSize(0.025);
  tmpSPECMJD.GetYaxis().SetTitleOffset(1.5);
  tmpSPECMJD.GetYaxis().SetLabelSize(0.025);
  tmpSPECMJD.GetXaxis().SetTitleSize(0.0);
  tmpSPECMJD.GetXaxis().SetLabelSize(0.0);
  if PAR == "hr2":
    tmpSPECMJD.GetXaxis().SetTitleSize(0.025);
    tmpSPECMJD.GetXaxis().SetLabelSize(0.025);    
  tmpSPECMJD.SetFillColor(3)
  SPECMJD_DICT[PAR]=tmpSPECMJD
  



################ Draw graph.

hard_co = 4
soft_co = 2

XPX=1024
NPANEL=5
YPX=150*NPANEL
    
c0= TCanvas("c0","c0",XPX,YPX)
TOPMGN=0.03
BTMMGN=0.15
MarkerStyle=20

HSIZE=math.ceil((1-TOPMGN-BTMMGN)/NPANEL*100)*0.01
BTMMGN=1-TOPMGN-HSIZE*NPANEL
#    print TOPMGN, BTMMGN, HSIZE

pad={}
PINDEX=0
for PAR in dRESULT.keys():
  PADNAME="pad%s"%(PAR)
  pad[PAR] = TPad(PADNAME, PADNAME, 0., 0., 1., 1.)
  BMGN=1-TOPMGN-HSIZE*(PINDEX+1)
  TMGN=TOPMGN+PINDEX*HSIZE
  pad[PAR].SetTopMargin(TMGN)
  pad[PAR].SetBottomMargin(BMGN)
  pad[PAR].SetLeftMargin(0.15)
  pad[PAR].SetRightMargin(0.02)
  pad[PAR].SetFillColor(0)
  pad[PAR].SetFillStyle(0)
  PINDEX+=1

for PAR in dRESULT.keys():
  pad[PAR].Draw()
  pad[PAR].cd(0)
  dGRAPH_hard[PAR].SetTitle("")
  dGRAPH_hard[PAR].GetXaxis().SetNdivisions(505)
  dGRAPH_hard[PAR].GetYaxis().SetNdivisions(505)
  dGRAPH_hard[PAR].GetYaxis().SetTitleSize(0.04)
  dGRAPH_hard[PAR].GetYaxis().SetTitleOffset(2.25)
  dGRAPH_hard[PAR].GetYaxis().SetLabelSize(0.025)
  dGRAPH_hard[PAR].SetMarkerSize(0.5)
  dGRAPH_hard[PAR].SetMarkerStyle(MarkerStyle)
  dGRAPH_hard[PAR].SetLineColor(hard_co)
  dGRAPH_hard[PAR].SetMarkerColor(hard_co)

  dGRAPH_soft[PAR].SetTitle("")
  dGRAPH_soft[PAR].GetXaxis().SetNdivisions(505)
  dGRAPH_soft[PAR].GetYaxis().SetNdivisions(505)
  dGRAPH_soft[PAR].GetYaxis().SetTitleSize(0.04)
  dGRAPH_soft[PAR].GetYaxis().SetTitleOffset(2.25)
  dGRAPH_soft[PAR].GetYaxis().SetLabelSize(0.025)
  dGRAPH_soft[PAR].SetMarkerSize(0.5)
  dGRAPH_soft[PAR].SetMarkerStyle(MarkerStyle)
  dGRAPH_soft[PAR].SetLineColor(soft_co)
  dGRAPH_soft[PAR].SetMarkerColor(soft_co)
      
  pad[PAR].SetGridy(1);
  gStyle.SetGridColor(16);
  SPECMJD_DICT[PAR].Draw("apz")
  dGRAPH_hard[PAR].Draw("samepzs")
  dGRAPH_soft[PAR].Draw("samepz")

c0.Modified()
c0.Update()
c0.Print("3bandlc+2hr.eps")
time.sleep(1000)
   
