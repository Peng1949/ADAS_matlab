% ���ԣ����������Ǽ���ǶȲ����Ƶ���Ƕȣ��������㳵�����·��ĽǶȣ������Ƕ��ڵ�����ʱ��     
clear; 
clc;
close all
%% ���ݵ���
origin_address = ['./data/att_image/0216_VN300/'];
origin_name = 'log-rec_20160924_153548';
address_log = [origin_address, origin_name, '.txt'];
fid_log = fopen(address_log,'r');

% ��Ҫ����ipm��ʾ��image�ļ�����
ipm_image_file_name = 'rec_20160924_153548';
ipm_index = 300; % ����һ֡ͼƬ��ʼipm
ipm_step = 2; % ����

% imu����
w_drift = [0, -2.83/180*pi, 0]';  % ͨ�����Ա�

%% ���Ʋ���
SHOW_IPM = 1; % ��ʾIPMͼ

%% ��ʼ������
camera_parameter.m= 720; % v (height)
camera_parameter.n = 1280; % u (width)
camera_parameter.yaw = 0*pi/180; % (�Ҷ������NE,yaw��Ϊ����njʽ��Ϊ��)
pitch_origin = 0.5;
camera_parameter.pitch =  pitch_origin*pi/180; % 2.373; 
camera_parameter.roll = 0; % ˮƽ���

camera_parameter.h = 1.3; %1.2; % Distance camera was above the ground (meters)
camera_parameter.dl = 0.05; % ����ƫ�� ����Ϊ��
camera_parameter.d = 0;

camera_parameter.Pc =  [camera_parameter.dl 0 -camera_parameter.h]'; % ��������ϵ��������������  ;
fx = 1482.0; %1506.64297;
fy = 1475.874; %1504.18761;
cx = 685.044; %664.30351;
cy = 360.02380; %340.94998;
camera_parameter.M1 = [ fx  0 cx; 
                        0  fy cy; 
                        0  0  1 ];
% ����ͼ ����
camera_parameter.x_min = 1; % ����ͷpitch���ϣ����½����뿴������
camera_parameter.x_max = 70; % ����
camera_parameter.y_min = -6;
camera_parameter.y_max = 6; % ����
camera_parameter.H1 = 400;
camera_parameter.W1 = 250;  %��Ҫ��ʾͼ��ĸߺͿ�
camera_parameter.zoom = 20;

% ��������
car_parameter.L = 2.637;
car_parameter.K_s2w = 0.0752;% ������ת��->ǰ��ת��

gyro_fliter = [0 0 0]';
k_camera = 0;
k_imu = 0;
k_vn = 0;
line_index_t = 0; % �������ԣ�����ǰ�����ڼ���

%% ��ȡ���� ���������֡ͼƬ
road_lean_fliter = [0 0 0]'; % ��ͨ�˲����Ƶ�·�¶�
dt = 0.01;
is_first_imu_data = 1;
vn_att_pre = [0 0 0]';

att_image_pitch_pre = 0;

is_first_vn_data = 1;
road_lean_fliter_vn = [0 0 0]';

is_first_image = 1;
pitch_new = 0;
while (1)
      %% ͼƬ IPM      
        % ��ȡͼƬ����
        image_name = sprintf('/%08d.jpg',300);
        str_data = [origin_address, ipm_image_file_name, image_name];
        I_rgb = imread(str_data);
        I_g = rgb2gray(I_rgb);
        [m, n] = size(I_g);
        
        pitch_new = pitch_new + 0.2/180*pi
        camera_parameter.pitch = pitch_new;
        % IPM�任
        [ CC_rgb ] = fun_IPM( I_rgb, camera_parameter );   
        CC_rgb(:,:, 1) = medfilt2(CC_rgb(:,:, 1),[2,2]);% ��ֵ�˲�
        CC_rgb(:,:, 2) = medfilt2(CC_rgb(:,:, 2),[2,2]);% ��ֵ�˲�
        CC_rgb(:,:, 3) = medfilt2(CC_rgb(:,:, 3),[2,2]);% ��ֵ�˲�

        figure();
        str_name = sprintf('frame%d����ͼ', ipm_index);
        title(str_name); 
        imshow(CC_rgb); 
        tt =1;
    
end
fclose(fid_log);
if SAVE_R
     fclose(fp);
end 
