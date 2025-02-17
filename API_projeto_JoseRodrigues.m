% NOME: JOSÉ RODRIGUES
% 
% Nº:2019246536
%
%
% OBJETIVO: *SISTEMA DE AQUISIÇÃO DE DADOS PARA UM LEITOR DIGITAL VERDE*
% RECORTE E SELEÇÃO DE UMA ÁREA DE INTERESSE DE UM SEGMENTO DE VÍDEO E
% REMOÇÃO DO BACKGROUND, PARA OBTENÇÃO DAS MATRIZES DE INTENSIDADE DOS
% PIXEIS DOS DIGITOS, O QUE PERMITE CALCULAR A INTENSIADE TOTAL DOS
% ALGARISMOS DE UM LEITOR DIGITAL VERDE (COM O INTUITO DE IDENTIFICAR ESSES
% ALGARISMOS A PARTIR DOS DADOS DE INTENSIDADE E ASSOCIÁLOS AO INSTANTE DE
% TEMPO DO VIDEO).
%
% CATEGORIA:
% 
% 
% INPUTS:
% VIDEO
% 
% OUTPUTS:
% MATRIZES DAS INTENSIDADES CORRESPONDESTES AOS ALGARISMOS
% INSTANTE CORRESPONDENTE À AQUISIÇÃO
% INTENSIDADE MÉDIA DO ALGARISMO
% 
% HISTÓRICO DE MODIFICAÇÃO:
% 

clear all; clc;
close all;



fig = uifigure('Name','GUI','Position',[55   333   219   183]);
p = uipanel(fig,'Position',[11    11   199   163]);
text=uilabel(p,'Position',[20 100 160 22],'Text','Escolha Ficheiro de Video');
button_click = uicontrol(p,'Position',[30 30 140 60],'String','Clique Aqui','Callback','uiresume(fig)');
uiwait(fig);
closereq

[file,path,indx] = uigetfile;
if isequal(file,0)
   disp('User selected Cancel')
else
   disp(['User selected ', fullfile(path, file),... 
         ' and filter index: ', num2str(indx)])
end

vid=VideoReader(file); %ficheiro de vídeo

%%
%########################## GUI ###########################################
fig = uifigure('Name','GUI','Position',[55   333   220   220]);
p = uipanel(fig,'Position',[11    11   200   200]);
text=uilabel(p,'Position',[5 140 200 80],'Text','Escolha Intervalo de Tempo (em s), que não exceda 10s.');
text.WordWrap='on';
box_start = uieditfield(p,'numeric','Position',[11 120 70 22],'Value',15);
box_start.Limits = [0 vid.Duration];
text_start=uilabel(p,'Position',[91 120 70 22],'Text','start (s)');
box_finish = uieditfield(p,'numeric','Position',[11 80 70 22],'Value',17);
box_finish.Limits = [box_start.Value vid.Duration];
text_finish=uilabel(p,'Position',[91 80 70 22],'Text','finish (s)');
button_start = uicontrol(p,'Position',[11 40 140 22],'String','CONTINUAR','Callback','uiresume(fig)');
uiwait(fig);

start=box_start.Value; %instante correspondente ao primeiro frame que se pretende
vid.CurrentTime = start;
finish = box_finish.Value; %instante correspondente ao ultimo frame que se pretende
first_frame=readFrame(vid);
closereq
%%
%################################ BACKGROUND ##############################
figure(1);
set(gcf,'units','normalized','outerposition',[0 0 1 1]);
imshow(first_frame);title('ESCOLHA DA ÁREA DE INTERESSE: BACKGROUND DO LEITOR DIGITAL (aplicar zoom antes da seleção)');
roi_b=drawrectangle; %região de interesse da imagem
window_b=roi_b.Position; %coordenadas do corte
background=imcrop(first_frame,window_b);
background=background(:,:,2); %componente verde do background
pause(10);
window_b=roi_b.Position; %coordenadas do corte
fprintf('loading...\n')
close

%%
%############################# DIGITO DIREITO ############################
figure(2);
set(gcf,'units','normalized','outerposition',[0 0 1 1]);
imshow(first_frame);title('DELIMITAR ÁREA COM UM DOS ALGARISMOS (aplicar zoom antes da seleção)')
roi=drawrectangle; %região de interesse da imagem
pause(10);
window=roi.Position; %coordenadas do corte
close

first_frame_crop=imcrop(first_frame,window);
sz=size(first_frame_crop);
background=imresize(background,[sz(1) sz(2)]); %dimensões da img do background  iguais à do corte dos frames
fprintf('loading...\n')

figure(3);
subplot(1,2,1);
imshow(background);title('Componente verde do Backgorund');
subplot(1,2,2);
histogram(background);title('Histograma de intensidade do Background');
pause(3);
fprintf('loading...\n')

%%
%--->RUN

s = struct('cdata',zeros(vid.Height,vid.Width,3,'uint8'),'colormap',[]);
k = 1;
vid.CurrentTime=start;
f4=figure('Name','HISTOGRAMAS DAS INTENSIDADES DA COMPONENTE VERDE DOS PÍXEIS'); f4.Position=[39   196   605   420];
f5=figure(5); f5.Position=[673   193   560   420];
while vid.CurrentTime <= finish
    s(k).cdata = readFrame(vid); %guarda todos os frames numa lista
    t(k)=vid.CurrentTime-start; % -> tempo decorrido
    frame=s(k).cdata;
    frame_crop=imcrop(frame,window);
    gframe_crop=frame_crop(:,:,2); %componente verde da imagem cortada
    
    set(0,'CurrentFigure',f4)
    subplot(1,3,1);
    imshow(frame_crop);title(['Frame nº: ',num2str(k)])

    subplot(1,3,2);xlabel('Intensidade dos verdes');
    imhist(gframe_crop);title('Hist C/ Background');
    ays=ylim;

    data{k}=gframe_crop-2*background; % -> DADOS DOS ESPETROS DE INTENSIDADE DOS ALGARISMOS
    subplot(1,3,3); xlabel('Intensidade dos verdes');
    imhist(data{k});title('Hist S/ Background');%a barra em contempla todos os 0 resultantes da eliminação do background
    ylim(ays);
    
    intensity(k)=sum(data{k},'all'); % -> intensidade total do Algarismo
    set(0,'CurrentFigure',f5)
    hold on
    scatter(k,intensity(k),'filled','r');title('Intensidade total da imagem do algarismo');
    xlabel('Nº do Frame');

    pause(0.01)

%     imshow(frame) %representação dos frames
    f(k)=k; % -> nº do frame

    k = k+1;
end

plot(intensity,'b');
hold off

%%
%############################## OUTPUT##############################
fig = uifigure('Name','GUI','Position',[55   333   220   220]);
p = uipanel(fig,'Position',[11    11   200   200]);
text=uilabel(p,'Position',[5 140 200 80],'Text','EXPORTAR DADOS PARA PATH DO PROGRAMA:');
text.WordWrap='on';

btn1 = uibutton(p,'push',...
               'Position',[5 120 190 30],...
               'Text','Dados: frame, tempo, intensidade',...
               'ButtonPushedFcn', @(btn1,event) exportDados(f,t,intensity));

btn2 = uibutton(p,'push',...
               'Position',[11 80 160 30],...
               'Text','Matrizes dos Digitos',...
               'ButtonPushedFcn', @(btn2,event) exportDigitos(k,data));

function exportDados(f,t,intensity)
    Dados=transpose(cat(1,f,t,intensity)); % dados da intensidade, tempo e frame
    writematrix(Dados,'Frame_Tempo_Intensidade.txt');
end

function exportDigitos(k,data)
    for i=1:k-1
        writematrix(data{i},append('Digito',num2str(i)),"FileType",'text'); % matrizes dos digitos
    end
end
