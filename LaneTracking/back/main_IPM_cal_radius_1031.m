%% ����������ȡlogԭʼ���ݵķ�ʽ����R
% �Ͼ�������
clc 
clear all
close all

SAVE_R = 1;  % �洢R�뾶���ı���
SHOW_IPM = 0; % ��ʾIPMͼ

%% ���ݵ���
origin_address = ['data/nj/1111_R_error/'];
origin_name = 'log';
address_log = [origin_address, origin_name, '.txt'];
fid = fopen(address_log,'r');

% ��Ҫ����ipm��ʾ��image�ļ�����
ipm_image_file_name = 'rec_20161016_102025';
ipm_index = 500; % ����һ֡ͼƬ��ʼipm
ipm_step = 4; % ����

% imu����
w_drift = [0, 0, -0.0204]';

%% ��������
% д��txt
save_R_addr = ['./', origin_address, origin_name, '-car_turn_radius.ini'];
if SAVE_R
     fp = fopen(save_R_addr, 'wt');
end  

%% ��ʼ������
camera_parameter.m= 720; % v (height)
camera_parameter.n = 1280; % u (width)
camera_parameter.yaw = 7.3*pi/180; % (�Ҷ������NE,yaw��Ϊ����njʽ��Ϊ��)
camera_parameter.pitch = 0.3*pi/180; % 2.373; 
camera_parameter.roll = 0; % ˮƽ���

camera_parameter.h = 1.25; %1.2; % Distance camera was above the ground (meters)
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
line_index_t = 0; % �������ԣ�����ǰ�����ڼ���
while ~feof(fid)
    line_index_t = line_index_t+1;

    %% ƥ��R��ͼƬ��ʱ��
    is_R_Camera_matched = 0;
    while ~is_R_Camera_matched
        % ���ļ�ĩβ���˳�
        if feof(fid)
           break;
        end
        
        lineData = fgetl(fid);
        str_line_raw = regexp(lineData,' ','split'); %�Կո�Ϊ�����ָ��ַ���
        time_s = str2num(str_line_raw{1,1});
        time_us = str2num(str_line_raw{1,2});
        time = time_s + time_us *1e-6;
        str_line_data_flag = str_line_raw(3);
        % Gsensor
        if  strcmp(str_line_data_flag, 'Gsensor')
            for i = 1:6
                imu_data_t(i, 1) = str2num(str_line_raw{1, i+3});
            end
            data_gensor_raw = [time; imu_data_t]; 
            k_imu = k_imu + 1;
            data_imu = fun_imu_data_trans( data_gensor_raw );
            data_imu_save(:, k_imu) = data_imu;

            gyro_new = data_imu(5:7) - w_drift;
            gyro_fliter = funLowpassFilterVector3f( gyro_fliter, gyro_new, 0.01, 1 );
            gyro_fliter_save(:, k_imu) = gyro_fliter;

        % speed
        elseif strcmp(str_line_data_flag, 'brake_signal')
            speed_cur = str2num(str_line_raw{1, 24})/3.6;        
        % camera
        elseif strcmp(str_line_data_flag, 'cam_frame')                              
            % ��ȡ����
            t_s = str_line_raw{1, 1};
            t_us = str_line_raw{1, 2};
            R_image_file_name = str_line_raw{1, 4}; % mp4�ļ�·��
            length_imege_name = length(R_image_file_name);
            R_mp4_file_name_cur_search = R_image_file_name(length_imege_name-22:length_imege_name-4); 
            R_image_index_str = str_line_raw{1, 5};
            R_image_index_num = str2num(R_image_index_str) + 1; % log��ͼ��index����Ǵ�0��ʼ

            % ����뾶
            if abs(gyro_fliter(3)) > 0.01 && speed_cur>15/3.6  
                R_imu_speed_cur = speed_cur/gyro_fliter(3); 
            else
                R_imu_speed_cur = 0;      
            end
            k_camera = k_camera + 1;
            R_imu_speed_save(k_camera) = R_imu_speed_cur;
%             R_imu_speed_cur

            if SAVE_R  % д��txt                    
                fprintf(fp, '%s %s %s %s %f ', t_s, t_us, R_image_file_name, R_image_index_str, R_imu_speed_cur );
                fprintf(fp, ' \n');
            end

             % �ȶԵ�ǰͼ���ʱ���
            if SHOW_IPM
                if strcmp(R_mp4_file_name_cur_search, ipm_image_file_name) && ipm_index == R_image_index_num                    
                    ipm_index
                    R_imu_speed_cur
                  %% ͼƬ IPM      
                    % ��ȡͼƬ����
                    image_name = sprintf('/%08d.jpg',ipm_index);
                    str_data = [origin_address, ipm_image_file_name, image_name];
                    I_rgb = imread(str_data);
                    I_g = rgb2gray(I_rgb);
                    [m, n] = size(I_g);
                    % IPM�任
                    [ CC_rgb ] = fun_IPM( I_rgb, camera_parameter );   
                    CC_rgb(:,:, 1) = medfilt2(CC_rgb(:,:, 1),[2,2]);% ��ֵ�˲�
                    CC_rgb(:,:, 2) = medfilt2(CC_rgb(:,:, 2),[2,2]);% ��ֵ�˲�
                    CC_rgb(:,:, 3) = medfilt2(CC_rgb(:,:, 3),[2,2]);% ��ֵ�˲�
                 %% ����
                    rgb_value_t = 240; % 0:��ɫ
                    [ CC_rgb ] = fun_plot_R( R_imu_speed_cur, CC_rgb, rgb_value_t, camera_parameter);                        
%                     figure(2);
%                     imshow(I_rgb);  
                    
                    figure(1);
                    str_name = sprintf('frame%d����ͼ', ipm_index);
                    title(str_name); 
                    imshow(CC_rgb); 

                    ipm_index = ipm_index + ipm_step;
                    is_R_Camera_matched = 1;
                end
            end
        end
    end
end
fclose(fid);
if SAVE_R
     fclose(fp);
end 
