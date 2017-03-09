% function R = steerGauss(I,Wsize,sigma,theta)
clc
clear all
close all

I_rgb = imread('00001697.jpg');
I_raw = rgb2gray(I_rgb);
I = I_raw(400:720, 200:1000);
figure();
title('ROIͼ'); 
imshow(I); 

% edge=zeros(m,n);
Wsize = 3;
sigma = 1;
theta = 30;

% ���Ƕ�ת����[0,pi]֮��
theta = theta/180*pi;
% �����ά��˹����x,y�����ƫ��gx,gy
k = [-Wsize:Wsize];
g = exp(-(k.^2)/(2*sigma^2));
gp = -(k/sigma).*exp(-(k.^2)/(2*sigma^2));
gx = g'*gp;
gy = gp'*g;
% ����ͼ�����x,y������˲����
Ix = conv2(I,gx,'same');
Iy = conv2(I,gy,'same');
% ����ͼ�����theta������˲����
J = cos(theta)*Ix+sin(theta)*Iy;figure,imshow(J);
figure,
subplot(1,3,1),axis image; colormap(gray);imshow(I),title('ԭͼ��');
subplot(1,3,2),axis image; colormap(gray);imshow(cos(theta)*gx+sin(theta)*gy),title('�˲�ģ��');
subplot(1,3,3),axis image; colormap(gray);imshow(J),title('�˲����'); 