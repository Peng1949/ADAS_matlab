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

while ~feof(fid_log)
    line_index_t = line_index_t+1;
    %% ƥ��R��ͼƬ��ʱ��
    is_image_index_matched = 0;
    while ~is_image_index_matched       
        if feof(fid_log) % ���ļ�ĩβ���˳�
           break;
        end
        
        lineData = fgetl(fid_log);
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
            
            % ������̬
            if is_first_imu_data == 1
                % ��һ�λ������ ���г�ʼ��
                acc_filter = data_imu(2:4, 1);
                gyro_filter = data_imu(5:7, 1);
                
                AccAngle = zeros(2,1);
                acc_init_data = data_imu(2:4, 1);
                AccAngle(1) = atan2(-acc_init_data(2), -acc_init_data(3)); % roll
                AccAngle(2) = atan2(acc_init_data(1), sqrt(acc_init_data(2)^2 + acc_init_data(3)^2));
                att = [AccAngle(1), AccAngle(2), 0]';
                Q = funEuler2Quat( att); 
                
                road_lean_fliter =  att;
                is_first_imu_data = 0; % ��ʼ������
            else
                acc_new = data_imu(2:4, 1);
                gyro_new = data_imu(5:7, 1);
                
                acc_filter = funLowpassFilterVector3f( acc_filter, acc_new, 0.01, 1 );
                gyro_new = gyro_new - w_drift;                
                gyro_filter = funLowpassFilterVector3f( gyro_filter, gyro_new, 0.01, 100 );
                gyro_filter_show = gyro_filter*180/pi;
                [GyroAngle, Q ,AccAngle] = funComplementaryFilter_q_new(Q, acc_filter, gyro_filter, dt );
                pitch_imu = GyroAngle(2)*180/pi;
                % ��·�¶ȹ���
                road_lean_fliter = funLowpassFilterVector3f( road_lean_fliter, GyroAngle, 0.01, 0.02 );
                road_lean_angle = road_lean_fliter(2)*180/pi;
                car_lean_angle = pitch_imu - road_lean_angle
               
                % ����ʹ��
                pitch_car2road = 0 + car_lean_angle;
%                 camera_parameter.pitch = pitch_car2road/180*pi;
                % save
                gyro_filter_save(:, k_imu) = gyro_filter*180/pi;
                GyroAngle_save(:, k_imu) = GyroAngle*180/pi;
            end

        % speed
        elseif strcmp(str_line_data_flag, 'brake_signal')
            speed_cur = str2num(str_line_raw{1, 24})/3.6;  
        % vn300(FMU) //  euler(3*2B) + vel(3*2B) + timestamp(4B) + angular_rate(3*2B) = 22B
        elseif strcmp(str_line_data_flag, 'FMU')
            for i = 1:3
                vn300_att(i, 1) = str2num(str_line_raw{1, i+4})/100;
                vn300_gyro(i,1) = str2num(str_line_raw{1, i+10})/100;
            end
            data_vn300_raw = [time; vn300_att];
            diff_vn_att = vn300_att - vn_att_pre;
            diff_vn_pitch = diff_vn_att(2);
            vn300_gyro_show = vn300_gyro;
            vn_att_pre = vn300_att;
            
            % �����¶�
            if(is_first_vn_data)
                road_lean_fliter_vn = vn300_att;
                is_first_vn_data = 0;
            end
            road_lean_fliter_vn = funLowpassFilterVector3f( road_lean_fliter_vn, vn300_att, 0.01, 0.2 );
            road_lean_angle_vn = road_lean_fliter_vn(2);
            car_lean_angle_vn = vn300_att(2) - road_lean_angle_vn
            
            % ����ʹ��
%             pitch_car2road_vn = pitch_origin + car_lean_angle_vn;
%             camera_parameter.pitch = vn300_att(2)/180*pi;
            
            %save
            k_vn =k_vn +1;
            gyro_vn_filter_save(:, k_vn) = vn300_gyro;
            vn300_att_save(:, k_vn) = vn300_att;
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

             % �ȶԵ�ǰͼ���ʱ���
            if SHOW_IPM
                if strcmp(R_mp4_file_name_cur_search, ipm_image_file_name) && ipm_index == R_image_index_num                    
                    ipm_index
                  %% ͼƬ IPM      
                    % ��ȡͼƬ����
                    image_name = sprintf('/%08d.jpg',ipm_index);
                    str_data = [origin_address, ipm_image_file_name, image_name];
                    I_rgb = imread(str_data);
                    I_g = rgb2gray(I_rgb);
                    [m, n] = size(I_g);
                    
                    % ������֮֡���pitch��ֵ
                    if is_first_image == 1
                        is_first_image = 0;
                        att_image_pitch_pre = pitch_imu;
                        pitch_test_new = 0.5;
                    end
                    diff_pitch_image = pitch_imu - att_image_pitch_pre
                    att_image_pitch_pre = pitch_imu;
                    pitch_test_new = pitch_test_new + diff_pitch_image
                    camera_parameter.pitch = pitch_test_new/180*pi;
                    % IPM�任
                    [ CC_rgb ] = fun_IPM( I_rgb, camera_parameter );   
                    CC_rgb(:,:, 1) = medfilt2(CC_rgb(:,:, 1),[2,2]);% ��ֵ�˲�
                    CC_rgb(:,:, 2) = medfilt2(CC_rgb(:,:, 2),[2,2]);% ��ֵ�˲�
                    CC_rgb(:,:, 3) = medfilt2(CC_rgb(:,:, 3),[2,2]);% ��ֵ�˲�
                    
                    figure(1);
                    str_name = sprintf('frame%d����ͼ', ipm_index);
                    title(str_name); 
                    imshow(CC_rgb); 
                    
                    % IPM�任 �̶�����
                    camera_parameter.pitch = pitch_origin*pi/180;
                    [ CC_rgb_origin ] = fun_IPM( I_rgb, camera_parameter );   
                    CC_rgb_origin(:,:, 1) = medfilt2(CC_rgb_origin(:,:, 1),[2,2]);% ��ֵ�˲�
                    CC_rgb_origin(:,:, 2) = medfilt2(CC_rgb_origin(:,:, 2),[2,2]);% ��ֵ�˲�
                    CC_rgb_origin(:,:, 3) = medfilt2(CC_rgb_origin(:,:, 3),[2,2]);% ��ֵ�˲�
                    
                    figure(2);
                    str_name = sprintf('frame%d����ͼ', ipm_index);
                    title(str_name); 
                    imshow(CC_rgb_origin);  
                    
                    ipm_index = ipm_index + ipm_step;
                    is_image_index_matched = 1;
                end
            end
        end
    end
end
fclose(fid_log);
if SAVE_R
     fclose(fp);
end 
