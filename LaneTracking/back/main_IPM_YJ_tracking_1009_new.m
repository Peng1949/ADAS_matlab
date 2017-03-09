% ���ٱ������
clc;
clear all; 
close all

SAVE_R = 0; % ����R
SHOW_IPM = 1; % �Ƿ�����IPM��ʾת��뾶 
%% ���ݵ���
% ת��뾶
source_addr = 'data/1011_���ٱ��/';

% ���ʱ��
% data_resample.mat---data_gensor_resample data_steer_resample data_speed_resample time_start fs_HZ
resample_data_addr = [source_addr, 'data_resample.mat'];
load(resample_data_addr);
% ����һ�������ǵ���Ư
data_gensor_resample_old = data_gensor_resample;
for i = 1:3
    w_drift(i, 1) = mean(data_gensor_resample(i+3, 14000:14100));
    data_gensor_resample(i+3, :) = data_gensor_resample(i+3, :) - w_drift(i,1);
end

image_file_name = '122230';
current_image_file_num = str2num(image_file_name);
camera_log_name = 'log-camera.ini';
addr_camera_log = [source_addr, camera_log_name]; % ���ʱ��  time_s,time_us,name,index
raw_data_camera_log = importdata( addr_camera_log )';
time_s = raw_data_camera_log(1, :);
time_us = raw_data_camera_log(2, :);
time_camera_log = time_s + time_us *1e-6 - time_start;
image_file_name_num = raw_data_camera_log(3, :);
NUM_camera = length(image_file_name_num);
j = 0;
for i = 1:NUM_camera
    if image_file_name_num(i) == current_image_file_num
        j = j + 1;
        data_camera_log(:, j) = [time_camera_log(i); raw_data_camera_log(4, i); raw_data_camera_log(3, i)];
    end
end

% ������������ ����������ÿ��8��������
address_lane = [source_addr, 'lane_feature_',image_file_name,'.txt'];
lane_feature_raw_data = load(address_lane)'; % data_lane: lane index*1, ���ҳ����ֱ�8����
NUM_lane = length(lane_feature_raw_data(1, :)); % ��ע����ͼ����������
lane_feature_data.frame_index = lane_feature_raw_data(1, :); % ͼ�������
for i = 1:8
    lane_feature_data.left_uv_feature(i, :, :) = lane_feature_raw_data(2*i:2*i+1, :);
    lane_feature_data.right_uv_feature(i, :, :) = lane_feature_raw_data(2*i+16:2*i+17, :);
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
camera_parameter.theta0 = 0.4*pi/180; % 2.373; 
camera_parameter.gama0 = 0; % ˮƽ���
camera_parameter.Pc =  [0 0 -camera_parameter.h]'; % ��������ϵ��������������  ;
fx = 1506.64297;
fy = 1504.18761;
cx = 664.30351;
cy = 340.94998;
camera_parameter.M1 = [fx  0 cx; 0  fy cy; 0  0  1 ];

h = camera_parameter.h; % Distance camera was above the ground (meters)
d = 0;	% ����ƫ��
l = 0;  % ����ƫ��
theta0 =camera_parameter.theta0;%2.373; 

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
camera_parameter.zoom = 10;

% ��������
car_parameter.L = 2.637;
car_parameter.K_s2w = 0.0752;% ������ת��->ǰ��ת��
L = 2.637;
L_r = L/2;
K_s2w = 0.07; %0.0752;% 0.059; % ������ת��->ǰ��ת��
fai = 0;
x_CAN = 0;
y_CAN = 0;
x_imu = 0; % ���ڱ���imu+speed����Ĺ켣
y_imu = 0;
  
%% ��ѭ��
save_i = 0;
save_yaw_i = 0;
current_index = 0; % ��ǰƥ���index
is_R_Camera_matched = 0; % R��ͼƬʱ���Ƿ�ƥ��
is_FirstTimeLoop = 1;
dyaw = 0;
gyro_fiter = [0 0 0]';
isHaveFirstMatch = 0;
beta = 0;
fai = 0;
steer_new = 0;
dt = 1/fs_HZ;
yaw_xy = 0;

for k_lane = 1:4:NUM_lane
    k = lane_feature_data.frame_index(k_lane)

    XY_CAN_pre = [x_CAN, y_CAN]';
    fai_pre  = fai;
    yaw_xy_pre = yaw_xy;
    % ������һ֡�����ߵ������㣬����Ԥ��
    if is_FirstTimeLoop == 1
        xy_L_pre = ones(2,8);
        xy_R_pre = ones(2,8);
    else
        line_p_L_pre = line_p_L;
        line_p_R_pre = line_p_R;
    end
    
    %% ƥ��R��ͼƬ��ʱ��
    is_R_Camera_matched = 0;
    while ~is_R_Camera_matched
        current_index = current_index + 1;
        dt_now = data_camera_log(1,k) - current_index/fs_HZ; % R����80hz���ز���
        dt_next = data_camera_log(1,k) - (current_index+1)/fs_HZ;
        if dt_now>0 && dt_next<=0
%             R_current_imu_speed = R_imu_speed(current_index);   
            is_R_Camera_matched = 1;
            isHaveFirstMatch = 1; 
        end
        
        if isHaveFirstMatch
        %% �����˶��켣����             
            speed_new = data_speed_resample(1, current_index)/3.6; 
            % imu + speed ����켣
%             gyro_new = data_gensor_resample(4:6, current_index) - [0 , 0, w_z_drift]';
            gyro_new = data_gensor_resample(4:6, current_index);
            gyro_fiter = funLowpassFilterVector3f( gyro_fiter, gyro_new, 1/fs_HZ, 20 );
            dyaw = dyaw + gyro_fiter(3)*1/fs_HZ;
            yaw_xy = yaw_xy + gyro_fiter(3)*1/fs_HZ;             

            vx = speed_new*cos(yaw_xy);
            vy = speed_new*sin(yaw_xy);
            x_imu = x_imu + vx*dt;
            y_imu = y_imu + vy*dt; 
            
            % ����һ��imu+speed�������������
            x_CAN = x_imu;
            y_CAN = y_imu;            
%             
            save_i = save_i + 1;
            save_xy(:, save_i) = [x_CAN, y_CAN]';
            save_steer(:, save_i) = steer_new;
            save_gyro(:, save_i) = gyro_new;
            save_yaw_xy(:, save_i) = yaw_xy*180/pi;
            save_xy_imu(:, save_i) = [x_imu, y_imu]';
        end
    end
    
%% Ԥ�⳵����
    % IPM����ֹ���ע��������ͼ���е�����
%     dyaw = -dyaw;
    dyaw_degree = dyaw*180/pi;
    Rn2c_kT = [ cos(dyaw) sin(dyaw);
                -sin(dyaw) cos(dyaw)];
            
    XY_CAN_cur = [x_CAN, y_CAN]';
    P_kT_t = XY_CAN_cur - XY_CAN_pre;
    dT_fai = yaw_xy_pre;
    dT_fai_deg = dT_fai*180/pi;
    R_dfai = [ cos(dT_fai) sin(dT_fai);
                -sin(dT_fai) cos(dT_fai)]; 
    P_kT = R_dfai*P_kT_t;      
    % ������IPM����������ϵ��
    for j = 1:8
        % Ԥ��
%         P_kT = [P_kT(1), 0]';
        XK_L_predict(:, j) = Rn2c_kT*( xy_L_pre(:, j) - P_kT); % Ԥ�⳵�����ڵ�ǰ֡������
        XK_R_predict(:, j) = Rn2c_kT*( xy_R_pre(:, j) - P_kT); % Ԥ�⳵�����ڵ�ǰ֡������
    end  
    % ������ʶ
    Y(:, 1) = XK_L_predict(2, :);
    X_t(:, 1) = XK_L_predict(1, :);
    I_8 = ones(8,1);
    X = [X_t.^2, X_t, I_8];
    line_p_L_predict(:, 1) = inv(X'*X)*X'*Y ;  
    
    Y(:, 1) = XK_R_predict(2, :);
    X_t(:, 1) = XK_R_predict(1, :);
    I_8 = ones(8,1);
    X = [X_t.^2, X_t, I_8];
    line_p_R_predict(:, 1) = inv(X'*X)*X'*Y;    
    
%% ��ϵ�ǰ����
    % IPM����ֹ���ע��������ͼ���е�����
    for j = 1:8
        % ����ʽ��ͶӰ�仯
        uv_L_new = [lane_feature_data.left_uv_feature(j, 1:2, k_lane)'; 1];
        xy_L_tmp = inv(R_IPM)*uv_L_new;
        s_2 = h/(xy_L_tmp(3)); % ����ϵ������Ϊ����߶��ǹ̶��ģ�
        xy_L_new = xy_L_tmp*s_2 + Pc; % ��������ϵ������
        xy_L_pre(:, j) = xy_L_new(1:2, 1); % ���浱ǰ�������㣬���ں����Ԥ��
        lane_feature_data.left_xy_feature(j, :, k_lane) = xy_L_new(1:2, 1);        
        
        uv_R_new = [lane_feature_data.right_uv_feature(j, 1:2, k_lane)'; 1];
        xy_R_tmp = inv(R_IPM)*uv_R_new;
        s_2 = h/(xy_R_tmp(3)); % ����ϵ������Ϊ����߶��ǹ̶��ģ�
        xy_R_new = xy_R_tmp*s_2 + Pc; % ��������ϵ������
        xy_R_pre(:, j) = xy_R_new(1:2, 1); % ���浱ǰ�������㣬���ں����Ԥ��
        lane_feature_data.right_xy_feature(j, :, k_lane) = xy_R_new(1:2, 1);
    end    
    % ������ʶ
    Y(:, 1) = lane_feature_data.left_xy_feature(:, 2, k_lane)';
    X_t(:, 1) = lane_feature_data.left_xy_feature(:, 1, k_lane)';
    I_8 = ones(8,1);
    X = [X_t.^2, X_t, I_8];
    line_p_L(:, 1) = inv(X'*X)*X'*Y ;
    
    Y(:, 1) = lane_feature_data.right_xy_feature(:, 2, k_lane)';
    X_t(:, 1) = lane_feature_data.right_xy_feature(:, 1, k_lane)';
    I_8 = ones(8,1);
    X = [X_t.^2, X_t, I_8];
    line_p_R(:, 1) = inv(X'*X)*X'*Y;      
            

    %% ����ת��뾶����
    if SAVE_R
        % д��txt
        fprintf(fp, '%d %f %f %f ', k, R_current_imu_speed );
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
        % ������ ��[0 0 0]' ��[10 50 50]'  ��[238,60,10] ��[30, 255, 30] ��[0 0 255]'
        [ CC_rgb ] = fun_plot_curve( line_p_L, CC_rgb, [0 0 255], camera_parameter ); % ��ʵ�ģ���
        [ CC_rgb ] = fun_plot_curve( line_p_L_predict, CC_rgb, [30, 255, 30], camera_parameter ); % Ԥ��ģ���
        if is_FirstTimeLoop ~= 1
            [ CC_rgb ] = fun_plot_curve( line_p_L_pre, CC_rgb, [238,60,10], camera_parameter );  % ֮ǰ�ģ���     
        end
        
        [ CC_rgb ] = fun_plot_curve( line_p_R, CC_rgb, [0 0 255], camera_parameter ); % ��ʵ�ģ���
        [ CC_rgb ] = fun_plot_curve( line_p_R_predict, CC_rgb, [30, 255, 30], camera_parameter ); % Ԥ��ģ���
        if is_FirstTimeLoop ~= 1
            [ CC_rgb ] = fun_plot_curve( line_p_R_pre, CC_rgb, [238,60,10], camera_parameter );  % ֮ǰ�ģ���     
        end        
        figure(1);
        str_name = sprintf('frame%d ��ע��ͼ',k);
        title(str_name); 
        imshow(CC_rgb);  
        
       %% ԭͼ��ʾ��ע��      
        % ��ȡͼƬ����
        image_name = sprintf('/%08d.jpg',k);
        str_data = [source_addr, image_file_name, image_name];
        I_rgb = imread(str_data);
        I_g = rgb2gray(I_rgb);
        [m, n] = size(I_g);
        
        for i = 1:8
             u_L = lane_feature_data.left_uv_feature(i, 1, k_lane);
             v_L = lane_feature_data.left_uv_feature(i, 2, k_lane);
             u_R = lane_feature_data.right_uv_feature(i, 1, k_lane);
             v_R = lane_feature_data.right_uv_feature(i, 2, k_lane);
             
             value_t = [238,60,10];
             I_rgb(v_L+1, u_L+1, :) = value_t;
             I_rgb(v_L+1, u_L+2, :) = value_t;
             I_rgb(v_L+2, u_L+1, :) = value_t;
             I_rgb(v_L+2, u_L+2, :) = value_t;
             
             value_t = [10 50 50];
             I_rgb(v_R+1, u_R+1, :) = value_t;
             I_rgb(v_R+1, u_R+2, :) = value_t;
             I_rgb(v_R+2, u_R+1, :) = value_t;
             I_rgb(v_R+2, u_R+2, :) = value_t;            
        end        
%         figure(2);
%         title(str_name); 
%         imshow(I_rgb);  
        
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
        is_FirstTimeLoop = 0;
%         dyaw = 0;
    end
    dyaw = 0;
end

% �˶��켣
figure()
plot(save_xy_imu(2, :), save_xy_imu(1, :)); hold on;
plot(save_xy(2, :), save_xy(1, :));
legend('imu+speed-trajectory', 'car-trajectory')
title('�켣')


figure()
plot(data_steer_resample); hold on;
plot(data_gensor_resample(6, :)*180/pi);
grid on;
legend('sterer', 'gyro-z')


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




