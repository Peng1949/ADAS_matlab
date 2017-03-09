% 0928: TODO ���Ӳ�ͼ��ʾ���Ż��ṹ
clc;
clear all; 
close all

SAVE_R = 0; % ����R
SHOW_IPM = 0; % �Ƿ�����IPM��ʾת��뾶 
%% ���ݵ���
source_addr = 'data/1024_nj_radius/16/';
% data_resample.mat---data_gensor_resample data_steer_resample data_speed_resample time_start fs_HZ
resample_data_addr = [source_addr, 'data_resample.mat'];
load(resample_data_addr);


%% ͼ��log
camera_log_name = '16log-camera.ini';
image_file_name = '163932';
current_image_file_num = str2num(image_file_name);
addr_camera_log = [source_addr, camera_log_name]; % ���ʱ��  time_s,time_us,name,index
raw_data_camera_log = importdata( addr_camera_log )';
time_s = raw_data_camera_log(1, :);
time_us = raw_data_camera_log(2, :);
time_camera_log = time_s + time_us *1e-6 - time_start;
image_file_name_num = raw_data_camera_log(4, :);
NUM_camera = length(image_file_name_num);
j = 0;
for i = 1:NUM_camera
    if image_file_name_num(i) == current_image_file_num
        j = j + 1;
        data_camera_log(:, j) = [time_camera_log(i); raw_data_camera_log(4, i); raw_data_camera_log(3, i)];
    end
end

% д��txt
save_R_addr = ['./', source_addr, 'car_move_radius.ini'];
if SAVE_R
     fp = fopen(save_R_addr, 'wt');
end  

%% ��ʼ������
camera_parameter.m= 720; % v (height)
camera_parameter.n = 1280; % u (width)
camera_parameter.h = 1.2; % Distance camera was above the ground (meters)
camera_parameter.theta0 = 1.8*pi/180; % 2.373; 
camera_parameter.gama0 = 0; % ˮƽ���
camera_parameter.Pc =  [0 0 -camera_parameter.h]'; % ��������ϵ��������������  ;
fx = 1506.64297;
fy = 1504.18761;
cx = 664.30351;
cy = 340.94998;
camera_parameter.M1 = [fx  0 cx; 0  fy cy; 0  0  1 ];

h = 1.2; % Distance camera was above the ground (meters)
d = 0;	% ����ƫ��
l = 0;  % ����ƫ��
theta0 = 1.8*pi/180;%2.373; 

% Y1 ����ڲ�
M1 = [fx   0 cx;
       0  fy cy;
       0   0  1 ];
Pc = [0 0 -h]'; % ��������ϵ��������������  
Rc12c = [0 1 0;% ���-ͼ������ϵ  
         0 0 1;
         1 0 0];
% �����̬����     
Ratt = [cos(theta0)  0  -sin(theta0);
             0        1        0;
         sin(theta0)  0  cos(theta0)];
Ratt_new = Rc12c*Ratt;
I3 = diag([1,1,1]);
R_IPM = M1*Rc12c*Ratt; % ����IPM

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

%% ��ѭ��
save_i = 0;
current_index = 0; % ��ǰƥ���index
is_R_Camera_matched = 0; % R��ͼƬʱ���Ƿ�ƥ��
is_FirstTimeLoop = 1;
gyro_fiter = [0 0 0]';

%% ����ת��뾶
%% ��� IMU ����Ԥ���� acc gyro
NUM_gsensor = length(data_gensor_resample(1,:));
NUM = length(data_gensor_resample);
clear time
for i = 1:NUM
    time(1, i) = 1/fs_HZ*i;
end
data_imu = [time; data_gensor_resample;];
imu_time = time;
NUM_imu = length(data_imu);

one_G = 9.80665; 
% Y1ģ��ļ��ٶȼ�У������
A0 = [0.0328    0.0079   -0.0003]'; %[0.0628    0.0079   -0.0003]';
A1 = [  1.0011    0.0028   -0.0141;
       -0.0161    1.0005    0.0181;
        0.0163   -0.0065    1.0140 ];
A2 = [ -0.0047    0       0;
         0      0.0039    0;
         0         0    0.0124];
% acc 
accel_range_scale = 8/(2^15);% acc_max_g = 8g
acc_raw = data_imu(2:4, :)*accel_range_scale;
acc_raw_G = acc_raw.*one_G;
inv_A1 = inv(A1);
for j = 1:NUM_imu
   acc_cal_tmp(:, j) = inv_A1*(acc_raw(:, j) - A0)*one_G;
end

% gyro
gyro_range_scale = 2000/180*pi/(2^15); %acc_max_g = 2000 degree/s   rad/s
gyro_cal_tmp = data_imu(5:7, :)*gyro_range_scale;

% ��������ƫ
for i = 1:3
%     w_drift(i) = mean(gyro_cal_tmp(i,2450:2460)); 
    gyro_cal_tmp(i,:) = gyro_cal_tmp(i,:); % - w_drift(i);
end

% Y1ģ��
acc_cal(1,:) = -acc_cal_tmp(3,:);
acc_cal(2,:) = -acc_cal_tmp(2,:);
acc_cal(3,:) = -acc_cal_tmp(1,:);
gyro_cal(1,:) = -gyro_cal_tmp(3,:);
gyro_cal(2,:) = -gyro_cal_tmp(2,:);
gyro_cal(3,:) = -gyro_cal_tmp(1,:);

IMU_w = gyro_cal;

NUM_speed = length(data_speed_resample(1,:));
dt = 1/80;
IMU_w_filter = IMU_w(:, 1);
NUM_loop = length(data_speed_resample);
for i = 1 : NUM_loop  % ���ݳ��ȿ��ܲ�һ��      
  % ����뾶
    if i < NUM_gsensor
        IMU_w_filter = funLowpassFilterVector3f( IMU_w_filter, IMU_w(:, i), dt, 1 );
        speed_new = data_speed_resample(1, i);
        if abs(IMU_w_filter(3)) < 0.01 % 0.01
            R_imu_speed(i) = 0;
        else
            R_imu_speed(i) = speed_new/IMU_w_filter(3);
        end  
        time_t = time_start + i*(1/fs_HZ);
        R_imu_speed_time(:, i) = [time_t, R_imu_speed(i)];
    end 
end


for k = 1:NUM_camera
    save_i = save_i + 1;
    
    %% ƥ��R��ͼƬ��ʱ��
    is_R_Camera_matched = 0;
    while ~is_R_Camera_matched
        current_index = current_index + 1;
        dt_now = data_camera_log(1,k) - current_index/fs_HZ; % R����80hz���ز���
        dt_next = data_camera_log(1,k) - (current_index+1)/fs_HZ;
        if dt_now>0 && dt_next<=0
            R_current_imu_speed = R_imu_speed(current_index);   
            R_image_file_name = raw_data_camera_log(3, current_index);
            is_R_Camera_matched = 1;
        end
 
    end
        

    %% ����ת��뾶����
    if SAVE_R
        % д��txt
        fprintf(fp, '%d %f %d ', k, R_current_imu_speed, R_image_file_name);
        fprintf(fp, ' \n');
    end

    if SHOW_IPM
    %% ͼƬ IPM      
        % ��ȡͼƬ����
        image_name = sprintf('/%08d.jpg',k);
        str_data = [source_addr, image_file_name, image_name];
        I_rgb = imread(str_data);
        I_g = rgb2gray(I_rgb);
        [m, n] = size(I_g);

        % �����趨�ĸ���ͼ�е��������أ���תΪ��������ϵXYZ����ͨ��С�׳���ģ��ӳ�䵽���ͼ���е�uv
        % �������Ա�֤����ͼ�����е����ض����ж�Ӧ����������
        % IPM�任
        [ CC_rgb ] = fun_IPM( I_rgb, camera_parameter );   
        CC_rgb(:,:, 1) = medfilt2(CC_rgb(:,:, 1),[2,2]);% ��ֵ�˲�
        CC_rgb(:,:, 2) = medfilt2(CC_rgb(:,:, 2),[2,2]);% ��ֵ�˲�
        CC_rgb(:,:, 3) = medfilt2(CC_rgb(:,:, 3),[2,2]);% ��ֵ�˲�

       %% ����
        % R_current_imu_speed
%         rgb_value_t = 240; % 0:��ɫ
%         [ CC_rgb ] = fun_plot_R( R_current_imu_speed, CC_rgb, rgb_value_t, camera_parameter);

        
        figure(1);
        str_name = sprintf('frame%d����ͼ',k);
        title(str_name); 
        imshow(CC_rgb);       
        
        is_FirstTimeLoop = 0;

    end
end




