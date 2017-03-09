% 2016.09.19������speed + IMU����ת��뾶
clc;
clear all; 
close all

SAVE_R = 0; % ����R
SHOW_IPM = 1; % �Ƿ�����IPM��ʾת��뾶 

%% ת��뾶 ���� 
% R_VNw_speed R_steer R_VN300 time_start
load data/0902_R/R_data_new.mat;
% ���ʱ��
raw_data_camera_log = importdata('data/0902_R/0912_VN300-camera_155524.ini')';
% raw_data_camera_log = importdata('data/0902_R/0912_VN300-camera_160025.ini')';
% raw_data_camera_log = importdata('data/0902_R/0912_VN300-camera_160526.ini')';
% raw_data_camera_log = importdata('data/0902_R/0912_VN300-camera_161027.ini')';
time_s = raw_data_camera_log(1, :);
time_us = raw_data_camera_log(2, :);
time_camera_log = time_s + time_us *1e-6 - time_start;
data_camera_log = [time_camera_log; raw_data_camera_log(3, :)];

%% ��ʼ������
m = 720; % v (height)
n = 1280; % u (width)
h = 1.22; % Distance camera was above the ground (meters)
d = 0;	% ����ƫ��
l = 0;  % ����ƫ��
theta0 = 1.8*pi/180; % 2.373; 
gama0 = 0; % ˮƽ���

% Y1 ����ڲ�
fx = 1506.64297;
fy = 1504.18761;
cx = 664.30351;
cy = 340.94998;
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

%����ͼ ����
y_max = 10; % ����
y_min = -10;
x_max = 70; % ����
x_min = 1; % ����ͷpitch���ϣ����½����뿴������
zoom = 20;
H1 = 400;W1=250;  %��Ҫ��ʾͼ��ĸߺͿ�

%% ��������
L = 2.637;
L_r = L/2;
K_s2w = 0.07; %0.0752;% 0.059; % ������ת��->ǰ��ת��
fai = 0;
x_CAN = 0;
y_CAN = 0;

fai_n = 0;
x_CAN_n = 0;
y_CAN_n = 0;

% д��txt
if SAVE_R
    fp = fopen('F:\Develop\ADAS\Code\matlab\LaneTracking_0803\data\0902_R\car_move_radius_frame_160025.ini', 'wt');
end    
%% ��ѭ��
R_index = 0;
is_R_Camera_matched = 0; % R��ͼƬʱ���Ƿ�ƥ��
% 1900:5:3700
% 4600:5:7000
k_R = 70;
for k = 3000:2:7734
    %% ƥ��R��ͼƬ��ʱ��
    is_R_Camera_matched = 0;
    while ~is_R_Camera_matched
        R_index = R_index + 1;
        dt_now = time_camera_log(k) - R_index/80; % R����80hz���ز���
        dt_next = time_camera_log(k) - (R_index+1)/80;
        if dt_now>0 && dt_next<=0
            R_current_VNw_speed = R_VNw_speed(R_index);
            R_current_VN300 = R_VN300(R_index);
            R_current_steer = R_steer(R_index);            
            is_R_Camera_matched = 1;
        end            
    end
%  k
%% ��������
if SAVE_R
    % д��txt
    fprintf(fp, '%d %f %f %f ', k, R_current_VNw_speed, R_current_VN300, R_current_steer);
    fprintf(fp, ' \n');
end
   
if SHOW_IPM
    %% ͼƬ IPM      
        % ��ȡͼƬ����
        str_data = sprintf('data/0902_R/frame_155524/%08d.jpg',k);
%         str_data = sprintf('data/0902_R/frame_160025/%08d.jpg',k);
%         str_data = sprintf('data/0902_R/frame_160526/%08d.jpg',k);
        I = imread(str_data);
        I_g = rgb2gray(I);
        [m, n] = size(I_g);
        CC = I_g;    

        % �����趨�ĸ���ͼ�е��������أ���תΪ��������ϵXYZ����ͨ��С�׳���ģ��ӳ�䵽���ͼ���е�uv
        % �������Ա�֤����ͼ�����е����ض����ж�Ӧ����������
        R_w2i =  M1*Rc12c*Ratt*[I3 -Pc];
        for M = 1:H1               %�任֮��·��ͼ��H1*W1=400*600�����أ�·����Ϊ7m���߶�Ϊ10m
            x = -(M*x_max/H1 - x_max);
            for N=1:W1            
                y = N*2*y_max/W1 - y_max; 
                if x<x_max && x>x_min && y>y_min && y<y_max
                    % ͶӰ�仯���������ģ��
                    Point_xyz = [x, y, 0, 1]';
                    uv_tmp = R_w2i*Point_xyz;
                    uv_new = uv_tmp/(uv_tmp(3));% z������ȹ�һ��
                    u = round(uv_new(1));
                    v = round(uv_new(2));                
                    if u>0.5 && v>0.5 && u<n && v<m
                        CC1(M, N) = I_g(v,u);
                    end  
                end
            end
        end     
        CC1 = medfilt2(CC1,[2,2]);% ��ֵ�˲�

        %% �����
        R_current = R_current_VN300; %R_current_VNw_speed; %R_current_VN300;
        if R_current ~=0
            j = 0;  
            R_current_abs = abs(R_current);
            x_max_t = min([x_max, R_current_abs]);
            for x_line = x_min:0.1:x_max_t
                if R_current>0
                    y_line = R_current - sqrt(R_current^2 - x_line^2);
                else
                    y_line = R_current + sqrt(R_current^2 - x_line^2);
                end
                M = (-x_line + x_max)*H1/x_max; % �����ظ�����
                if x_line<x_max_t && x_line>x_min && y_line>y_min && y_line<y_max  
                    N = (y_line + y_max)*W1/(2*y_max);
                    u = round(N);
                    v = round(M);
                    if u>0.5 && v>0.5 && u<W1 && v<H1
                         CC1(v, u) = 220;
                         CC1(v+1, u) = CC1(v, u);
                         CC1(v, u+1) = CC1(v, u);
                         CC1(v+1, u+1) = CC1(v, u);
                         j = j+1;
                        line_pre(:, j) = [u, v]';
                        line_R_XY(:, j) = [x_line, y_line]';
                    end  
                end
            end
        end

        %%% R_current_steer
        %%% �����
%         k_R = k_R - 1
        R_current = R_current_steer; % R_current_VN300; %R_current_steer;
        if R_current ~=0
            j = 0;    
            R_current_abs = abs(R_current);
            x_max_t = min([x_max, R_current_abs]);
            for x_line = x_min:0.1:x_max_t
                if R_current>0
                    y_line = R_current - sqrt(R_current^2 - x_line^2);
                else
                    y_line = R_current + sqrt(R_current^2 - x_line^2);
                end          
                M = (-x_line + x_max)*H1/x_max; % �����ظ�����
                if x_line<x_max_t && x_line>x_min && y_line>y_min && y_line<y_max  
                    N = (y_line + y_max)*W1/(2*y_max);
                    u = round(N);
                    v = round(M);
                    if u>0.5 && v>0.5 && u<W1 && v<H1
                         CC1(v, u) = 180; % 0:��ɫ
                         CC1(v+1, u) = CC1(v, u);
                         CC1(v, u+1) = CC1(v, u);
                         CC1(v+1, u+1) = CC1(v, u);
                         j = j+1;
                        line_pre(:, j) = [u, v]';
                        line_R_XY(:, j) = [x_line, y_line]';
                    end  
                end
            end
        end

        %%% ����ͷ����
        x_max_t = x_max;
        for x_line = x_min:0.1:x_max_t
            y_line = 0;            
            M = (-x_line + x_max)*H1/x_max; % �����ظ�����
            if x_line<x_max_t && x_line>x_min && y_line>y_min && y_line<y_max  
                N = (y_line + y_max)*W1/(2*y_max);
                u = round(N);
                v = round(M);
                if u>0.5 && v>0.5 && u<W1 && v<H1
                     CC1(v, u) = 70; % 0:��ɫ
                     CC1(v+1, u) = CC1(v, u);
                     CC1(v, u+1) = CC1(v, u);
                     CC1(v+1, u+1) = CC1(v, u);
                end  
            end
        end
        
        figure(1);
        imshow(CC1);
        str_name = sprintf('frame%d����ͼ',k);
        title(str_name); 
        
        % ����ipmͼ
%         str_name = sprintf('data/0902_R/ipm_save/%d_IPM.png',k);
%         str_name = sprintf('ipm/%d.jpg',k);
%         imwrite(CC1,str_name)

         CC1(:,:) = 0; % ����ˢ��ͼ
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

