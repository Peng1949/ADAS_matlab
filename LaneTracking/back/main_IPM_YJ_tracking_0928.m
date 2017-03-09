% 0804:����0801�ɼ���IMU��CAN��IMU��Camera���ݣ���ͼ����г������˹���ע�󣬽���lane tracking�������
% 0805��ʵ���˳����ߵ�tracking,Ŀǰ�������Ȼ����ԡ����Ƕ���(0,0)�����������쳣����������
% 2016.09.19������speed + IMU����ת��뾶
% 0928: TODO ���Ӳ�ͼ��ʾ���Ż��ṹ
clc;
clear all; 
close all

SAVE_R = 1; % ����R
SHOW_IPM = 1; % �Ƿ�����IPM��ʾת��뾶 

%% ת��뾶 ���� 
% R_imu_speed R_VNw_speed R_steer R_VN300 time_start

source_addr = 'data/0924_R/';
image_file_name = 'rec_20160924_155552';
camera_log_name = '0921_VN300-camera_155552.ini';

% ת��뾶
R_addr = [source_addr, 'R_data.mat'];
load(R_addr);

% ���ʱ��
addr_camera_log = [source_addr, camera_log_name];
raw_data_camera_log = importdata( addr_camera_log )';
time_s = raw_data_camera_log(1, :);
time_us = raw_data_camera_log(2, :);
time_camera_log = time_s + time_us *1e-6 - time_start;
data_camera_log = [time_camera_log; raw_data_camera_log(3, :)];

% д��txt
save_R_addr = ['./', source_addr, 'car_move_radius.ini'];
if SAVE_R
     fp = fopen(save_R_addr, 'wt');
%     fp = fopen('./data/0924_R/car_move_radius_frame_162057.ini', 'wt');
end  

%% ��ʼ������
camera_parameter.m= 720; % v (height)
camera_parameter.n = 1280; % u (width)
camera_parameter.h = 1.22; % Distance camera was above the ground (meters)
camera_parameter.theta0 = 0.8*pi/180; % 2.373; 
camera_parameter.gama0 = 0; % ˮƽ���
camera_parameter.Pc =  [0 0 -camera_parameter.h]'; % ��������ϵ��������������  ;
fx = 1506.64297;
fy = 1504.18761;
cx = 664.30351;
cy = 340.94998;
camera_parameter.M1 = [fx  0 cx;
                     0  fy cy;
                     0   0  1 ];
% ����ͼ ����
camera_parameter.x_min = 1; % ����ͷpitch���ϣ����½����뿴������
camera_parameter.x_max = 70; % ����
camera_parameter.y_min = -10;
camera_parameter.y_max = 10; % ����
camera_parameter.H1 = 400;
camera_parameter.W1 = 300;  %��Ҫ��ʾͼ��ĸߺͿ�
camera_parameter.zoom = 20;

% ��������
car_parameter.L = 2.637;
car_parameter.K_s2w = 0.0752;% ������ת��->ǰ��ת��
% L = 2.637;
% L_r = L/2;
% K_s2w = 0.07; %0.0752;% 0.059; % ������ת��->ǰ��ת��
fai = 0;
x_CAN = 0;
y_CAN = 0;

  
%% ��ѭ��
R_index = 0;
is_R_Camera_matched = 0; % R��ͼƬʱ���Ƿ�ƥ��
% 1900:5:3700
% 4600:5:7000
for k = 1500:4:7734
    %% ƥ��R��ͼƬ��ʱ��
    is_R_Camera_matched = 0;
    while ~is_R_Camera_matched
        R_index = R_index + 1;
        dt_now = time_camera_log(k) - R_index/80; % R����80hz���ز���
        dt_next = time_camera_log(k) - (R_index+1)/80;
        if dt_now>0 && dt_next<=0
            R_current_VNw_speed = R_VNw_speed(R_index);
            R_current_VN300 = R_VN300(R_index);  
            R_current_imu_speed = R_imu_speed(R_index);   
            is_R_Camera_matched = 1;
        end            
    end

    %% ��������
    if SAVE_R
        % д��txt
        fprintf(fp, '%d %f %f %f ', k, R_current_imu_speed, R_current_VN300);
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
%         CC1 = medfilt2(CC1,[2,2]);% ��ֵ�˲�
        CC_rgb(:,:, 1) = medfilt2(CC_rgb(:,:, 1),[2,2]);% ��ֵ�˲�
        CC_rgb(:,:, 2) = medfilt2(CC_rgb(:,:, 2),[2,2]);% ��ֵ�˲�
        CC_rgb(:,:, 3) = medfilt2(CC_rgb(:,:, 3),[2,2]);% ��ֵ�˲�

       %% ����
        % R_current_imu_speed
        rgb_value_t = 240; % 0:��ɫ
        [ CC_rgb ] = fun_plot_lane( R_current_imu_speed, CC_rgb, rgb_value_t, camera_parameter);
        % ����ͷ����
        rgb_value_t = 40; % 0:��ɫ
        [ CC_rgb ] = fun_plot_lane( 0, CC_rgb, rgb_value_t, camera_parameter);
        
        figure(1);
        str_name = sprintf('frame%d����ͼ',k);
        title(str_name); 
        imshow(CC_rgb);        
        
        % ����ipmͼ
%         str_name = sprintf('data/0902_R/ipm_save/%d_IPM.png',k);
%         str_name = sprintf('ipm/%d.jpg',k);
%         imwrite(CC1,str_name)

%          CC1(:,:) = 0; % ����ˢ��ͼ
        %% save data
    %     angle_M_est =  atan(line_p_est(1,2));
    %     angle_M_camera =  atan(line_p(1,2));
    %     tracking_error(1, loopIndex) = (angle_M_est - angle_M_camera)*180/pi;
    %     tracking_error(2, loopIndex) = cos(angle_M_est)*line_p_est(2,2) - cos(angle_M_camera)*line_p(2,2);
    end
end
% % tracking error
% figure()
% subplot(2,1,1)
% plot(tracking_error(1,:));
% hold on;
% plot(save_lane_change_M(1, :)); % lane������Գ����˶�
% grid on;
% legend('tracking-angle-error', 'lane-angle-change');
% 
% subplot(2,1,2)
% plot(tracking_error(2,:));
% hold on;
% plot(save_lane_change_M(2, :)); % lane������Գ����˶�
% grid on;
% legend('tracking-angle-offset-error', 'lane-offset-change');

% figure()
% plot(-save_d_angle_line_M);
% hold on;
% grid on;
% plot(save_dyaw_degree);
% plot(save_fai_pre);
% legend('d-angle-line-M', 'dyaw-degree', 'fai-pre');
% 
% figure()
% plot(-save_angle_line_M);
% hold on;
% grid on;
% plot(save_yaw_degree);
% plot(save_fai);
% legend('angle-line-M', 'yaw-degree', 'fai');




