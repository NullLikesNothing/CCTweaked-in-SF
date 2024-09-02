local a=require("json").stringify;local b={}for c=0,15 do b[2^c]=string.format("%x",c)end;local d=function()end;local function e(f,g,h)local function i()return f end;return{write=d,blit=d,clear=d,clearLine=d,setCursorPos=d,setCursorBlink=d,setPaletteColour=d,setPaletteColor=d,setTextColour=d,setTextColor=d,setBackgroundColour=d,setBackgroundColor=d,getTextColour=d,getTextColor=d,getBackgroundColour=d,getBackgroundColor=d,scroll=d,isColour=i,isColor=i,getSize=function()return g,h end,getPaletteColour=term.native().getPaletteColour,getPaletteColor=term.native().getPaletteColor}end;local function j(k)local l={}local m={}local n={}local o={}local p={}local q,r=1,1;local s=false;local t="0"local u="f"local v,w=k.getSize()local x=k.isColor()local y=false;local z={}if k.getPaletteColour then for c=0,15 do local A=2^c;o[A]={k.getPaletteColour(A)}p[b[A]]=colours.rgb8(k.getPaletteColour(A))end end;function z.write(B)B=tostring(B)k.write(B)y=true;if r>w or r<1 or q+#B<=1 or q>v then q=q+#B;return end;if q<1 then B=B:sub(-q+2)q=1 elseif q+#B>v then B=B:sub(1,v-q+1)end;local C=l[r]local D=m[r]local E=n[r]local F=q-1;local G=math.min(1,F)local H=q+#B;local I=v;local J,K=string.sub,string.rep;l[r]=J(C,G,F)..B..J(C,H,I)m[r]=J(D,G,F)..K(t,#B)..J(D,H,I)n[r]=J(E,G,F)..K(u,#B)..J(E,H,I)q=q+#B end;function z.blit(B,L,M)k.blit(B,L,M)y=true;if r>w or r<1 or q+#B<=1 or q>v then q=q+#B;return end;if q<1 then B=B:sub(-q+2)L=L:sub(-q+2)M=M:sub(-q+2)q=1 elseif q+#B>v then B=B:sub(1,v-q+1)L=L:sub(1,v-q+1)M=M:sub(1,v-q+1)end;local C=l[r]local D=m[r]local E=n[r]local F=q-1;local G=math.min(1,F)local H=q+#B;local I=v;local J=string.sub;l[r]=J(C,G,F)..B..J(C,H,I)m[r]=J(D,G,F)..L..J(D,H,I)n[r]=J(E,G,F)..M..J(E,H,I)q=q+#B end;function z.clear()for c=1,w do l[c]=string.rep(" ",v)m[c]=string.rep(t,v)n[c]=string.rep(u,v)end;y=true;return k.clear()end;function z.clearLine()if r>w or r<1 then return end;l[r]=string.rep(" ",v)m[r]=string.rep(t,v)n[r]=string.rep(u,v)y=true;return k.clearLine()end;function z.getCursorPos()return q,r end;function z.setCursorPos(N,O)if type(N)~="number"then error("bad argument #1 (expected number, got "..type(N)..")",2)end;if type(O)~="number"then error("bad argument #2 (expected number, got "..type(O)..")",2)end;if N~=q or O~=r then q=math.floor(N)r=math.floor(O)y=true end;return k.setCursorPos(N,O)end;function z.setCursorBlink(P)if type(P)~="boolean"then error("bad argument #1 (expected boolean, got "..type(P)..")",2)end;if s~=P then s=P;y=true end;return k.setCursorBlink(P)end;function z.getCursorBlink()return s end;function z.getSize()return v,w end;function z.scroll(Q)if type(Q)~="number"then error("bad argument #1 (expected number, got "..type(Q)..")",2)end;local R=string.rep(" ",v)local S=string.rep(t,v)local T=string.rep(u,v)if Q>0 then for c=1,w do l[c]=l[c+Q]or R;m[c]=m[c+Q]or S;n[c]=n[c+Q]or T end elseif Q<0 then for c=w,1,-1 do l[c]=l[c+Q]or R;m[c]=m[c+Q]or S;n[c]=n[c+Q]or T end end;y=true;return k.scroll(Q)end;function z.setTextColour(U)if type(U)~="number"then error("bad argument #1 (expected number, got "..type(U)..")",2)end;local V=b[U]or error("Invalid colour (got "..U..")",2)if V~=t then y=true;t=V end;return k.setTextColour(U)end;z.setTextColor=z.setTextColour;function z.setBackgroundColour(U)if type(U)~="number"then error("bad argument #1 (expected number, got "..type(U)..")",2)end;local V=b[U]or error("Invalid colour (got "..U..")",2)if V~=u then y=true;u=V end;return k.setBackgroundColour(U)end;z.setBackgroundColor=z.setBackgroundColour;function z.isColour()return x==true end;z.isColor=z.isColour;function z.getTextColour()return 2^tonumber(t,16)end;z.getTextColor=z.getTextColour;function z.getBackgroundColour()return 2^tonumber(u,16)end;z.getBackgroundColor=z.getBackgroundColour;if k.getPaletteColour then function z.setPaletteColour(f,W,X,P)local Y=o[f]if not Y then error("Invalid colour (got "..tostring(f)..")",2)end;if type(W)=="number"and X==nil and P==nil then Y[1],Y[2],Y[3]=colours.rgb8(W)p[b[f]]=W else if type(W)~="number"then error("bad argument #2 (expected number, got "..type(W)..")",2)end;if type(X)~="number"then error("bad argument #3 (expected number, got "..type(X)..")",2)end;if type(P)~="number"then error("bad argument #4 (expected number, got "..type(P)..")",2)end;Y[1],Y[2],Y[3]=W,X,P;p[b[f]]=colours.rgb8(W,X,P)end;y=true;return k.setPaletteColour(f,W,X,P)end;z.setPaletteColor=z.setPaletteColour;function z.getPaletteColour(f)local Y=o[f]if not Y then error("Invalid colour (got "..tostring(f)..")",2)end;return Y[1],Y[2],Y[3]end;z.getPaletteColor=z.getPaletteColour end;function z.is_dirty()return y end;function z.clear_dirty()y=false end;function z.serialise()return a{packet=0x10,width=v,height=w,cursorX=q,cursorY=r,cursorBlink=s,curFore=t,curBack=u,palette=p,text=l,fore=m,back=n}end;z.setCursorPos(1,1)z.setBackgroundColor(colours.black)z.setTextColor(colours.white)z.clear()return z end;return{buffer=j,empty=e}