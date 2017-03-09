clc;
clear 
close all

%%
% camera_time camera_uv imu_time  acc_cal  gyro_cal
load('imu_camera.mat');

tmp1 = length(camera_time);
j = 0;
for i = 1:2:tmp1
    j = j + 1;
    camera_time_tmp(j) = camera_time(i);
    camera_uv_tmp(:,j) = camera_uv(:, i);
end
camera_time = camera_time_tmp;
camera_uv = camera_uv_tmp;


%����ڲ�
fx = 1437.72915;
fy = 1435.42215;
cx = 610.46050;
cy = 376.26171;
M1 = [fx   0 cx;
       0  fy cy;
       0   0  1 ];
Cimu2c = [0 1 0;
          0 0 1;
          1 0 0];

% ��ʼ������
NUM_imu = length(imu_time);
NUM_camera = length(camera_time);

isFirstTime = 1;
carmera_index = 1;% ��ʾ��ǰ��camera��֡���
Q_camera_pre = [1 0 0 0]';  % ��¼�ϴ�camera��������ʱ�����̬


acc_cal = -acc_cal;
acc_filter = acc_cal(: , 1); % һ�׵�ͨ��ļ��ٶȼ�ֵ
gyro_fiter = gyro_cal(: , 1);
acc_lowfilt_hz = 1; % ���ٶȼƵ�ͨ��ֹƵ��

% �ü��ٶȵ�ǰ50��100���ݵ�ƽ��ֵ�����ʼ�Ƕȣ���att����ֵ
AccAngle = zeros(2,1);
for i = 1:3
    acc_init_data(i) = mean(acc_cal(i, 50:100));
end
AccAngle(1) = atan2(acc_init_data(2), acc_init_data(3)); % roll
AccAngle(2) = -atan2(acc_init_data(1), sqrt(acc_init_data(2)^2 + acc_init_data(3)^2));
att = [AccAngle(1), AccAngle(2), 0]';
Q = funEuler2Quat( att); 
Q1 = Q;
GyroAngle = att;

dt_err_num = 0; % dt = 0ʱ��+1
%%
for i = 2:NUM_imu-1  
    IMU_time(i) = i;   
    dt = imu_time(i) - imu_time(i-1);
    if dt ~= 0
        % IMU����һ�׵�ͨ�˲�
        acc_new =  acc_cal(: , i);
        acc_filter = funLowpassFilterVector3f( acc_filter, acc_new, dt, acc_lowfilt_hz );
        gyro_fiter = gyro_cal(: , i);
        
        %�����˲�        
        [att, Q ,AccAngle] = funComplementaryFilter_q_new(Q, acc_filter, gyro_fiter, dt );
        [GyroAngle, Q1 ] = funComplementaryFilter_q(Q1, acc_filter, gyro_fiter,  dt );
        
        % test
        if carmera_index == 449
            kk = 1;
        end
        
        % �ж�cameraʱ�����ȡ�����ʱ���
        dt_current = abs(imu_time(i)-camera_time(carmera_index));
        dt_next = abs(imu_time(i+1)-camera_time(carmera_index));
        if dt_current < dt_next && carmera_index < NUM_camera
            if isFirstTime == 1 % �Ƿ��ǵ�һ�ν���
                isFirstTime = 0;
                Q_camera_pre = Q;
                camera_uv_pre = camera_uv(:, carmera_index);
            else
                carmera_index = carmera_index + 1;% ��ʾ��ǰIMU��cameraʱ�������ӽ��ģ�����Ԥ�����
                camera_uv_new = camera_uv(:, carmera_index);

                 % ��������˶�������Ԥ�����ص�����
                 Cc2n_pre = (Cimu2c*funQ2Cb2n(Q_camera_pre)')'; % c2n
                 Cn2c_current = (Cimu2c*funQ2Cb2n(Q)'); % n2c
                 C_dT = Cn2c_current*Cc2n_pre;                 
                 tmp = M1*C_dT*inv(M1)*[camera_uv_pre(1), camera_uv_pre(2), 1]';
                 camera_uv_estimation = [tmp(1), tmp(2)]';
                 camera_uv_true = camera_uv_new;                   
                 
                 % Ԥ��������ʵ����������
                 duv = camera_uv_estimation - camera_uv_true;
                 duv_rotation = camera_uv_pre - camera_uv_new; % ǰ����֡�������ص���˶�
                 dR = sqrt(sum(duv.^2)) ; % Ԥ���������뾶
                 dR_rotation = sqrt(sum(duv_rotation.^2)) ; % ����ת�����µ�ǰ����֡������ƫ��
                 
                 camera_uv_estimation_save(:, carmera_index-1) =  camera_uv_estimation;
                 camera_uv_true_save(:, carmera_index-1) = camera_uv_true;
                 duv_save(:, carmera_index-1) = duv; 
                 duv_rotation_save(:, carmera_index-1) = duv_rotation;
                 dR_save(:, carmera_index-1) = dR;
                 dR_rotation_save(:, carmera_index-1) = dR_rotation;
                 att_camera_rotation_save(:, carmera_index-1) = att*180/pi;
%                  if dR_rotation == 0 || dR_rotation<2
%                     dR_rotation_save(:, carmera_index-1) = 0;
%                  else
%                     dR_rotation_save(:, carmera_index-1) = dR/dR_rotation;
%                  end
                 
                 % preֵ����
                 camera_uv_pre = camera_uv_new;
                 Q_camera_pre = Q;
                 
            end            
        end
    else
        dt_err_num = dt_err_num + 1; % ���ݼ�¼�����ظ���ʱ��ʱ����ظ���
    end  
    
    acc_filter_save(:,i-1) = acc_filter;
    att_save(:,i-1) = att*180/pi;
    AccAngle_save(:,i-1) = AccAngle*180/pi;
    GyroAngle_save(:,i-1) = GyroAngle*180/pi;    

end

%% ������Ԥ��
figure()
% ʵ�ʵĵ�
subplot(2,1,1)
plot(camera_uv_true_save(1, :));
grid on;
hold on;
plot(camera_uv_estimation_save(1, :));
legend('ʵ��','Ԥ���')
title('X��');


subplot(2,1,2)
plot(camera_uv_true_save(2, :));
grid on;
hold on;
plot(camera_uv_estimation_save(2, :));
legend('ʵ��','Ԥ���')
title('Y��');

% %Ԥ���
% subplot(2,2,3)
% plot(camera_uv_estimation_save(1, :));
% grid on;
% legend('X');
% title('Ԥ��')
% 
% subplot(2,2,4)
% plot(camera_uv_estimation_save(2, :));
% grid on;
% legend('Y');
% title('Ԥ��')

%���
figure()
subplot(2,1,1);
plot(duv_save(1, :));
grid on;
hold on;
plot(duv_save(2, :));
plot(duv_rotation_save(1, :));
plot(duv_rotation_save(2, :));
% plot(camera_uv_true_save(1, :)/50);
% plot(camera_uv_true_save(2, :)/50);
% legend('dX','dY','X','Y');
legend('dX','dY','duv_rotation-X','duv_rotation-Y');
title('XY���')

subplot(2,1,2);
plot(dR_save);
grid on;
hold on;
plot(dR_rotation_save);
legend('dR','dR-rotation');
title('���뾶')

% �����������ʱ�����̬
figure()
plot(att_camera_rotation_save(1,:));
grid on;
hold on;
plot(att_camera_rotation_save(2,:));
plot(att_camera_rotation_save(3,:));
legend('X','Y','Z');
title('ͼ����������ʱ�����̬��')

%% ��̬��
% figure()
% plot(IMU_time(2:end),att_save(1, :));
% hold on;
% grid on;
% plot(IMU_time(2:end), AccAngle_save(1, :));
% plot(IMU_time(2:end), GyroAngle_save(1, :));
% legend('att', 'AccAngle', 'GyroAngle');
% 
% figure()
% plot(IMU_time(2:end), att_save(2, :));
% hold on;
% grid on;
% plot(IMU_time(2:end), AccAngle_save(2, :));
% plot(IMU_time(2:end), GyroAngle_save(2, :));
% legend('att', 'AccAngle', 'GyroAngle');
% 
% figure()
% plot(IMU_time(2:end), att_save(3, :));
% hold on;
% grid on;
% plot(IMU_time(2:end), GyroAngle_save(3, :));
% legend('att','GyroAngle');

%% IMU data plot 
% figure()
% % subplot(2,1,1)
% plot(IMU_time, acc_cal(1, :));
% hold on;
% plot(IMU_time, acc_cal(2, :));
% plot(IMU_time, acc_cal(3, :));
% grid on;
% plot(IMU_time, gyro_cal(1, :));
% plot(IMU_time, gyro_cal(2, :));
% plot(IMU_time, gyro_cal(3, :));
% legend('ax','ay','az','gx','gy','gz');


% subplot(2,1,2)
% plot(IMU_time, gyro_cal(1, :));
% hold on;
% plot(IMU_time, gyro_cal(2, :));
% plot(IMU_time, gyro_cal(3, :));
% grid on;
% legend('x','y','z');
% title('������')

