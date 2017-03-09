%%   �����ز���
clc
clear all
close all

%% gsensor : acc gyro
name_str = './log';
address_gensor = [name_str, '-gsensor.ini'];
data_raw_gensor = load(address_gensor)';
time_s = data_raw_gensor(1, :);
time_us = data_raw_gensor(2, :);
time = time_s + time_us *1e-6;
% ͳһ��ʼʱ��
time_start = time(1);
time = time - time_start;
% % �ж����ݴ�ʱ��0��ʼ
% NUM_t = length(time);
% data_gensor_raw = [time; data_raw_gensor(3:8, :)]; 
% [ data_imu ] = fun_imu_data_trans( data_gensor_raw );
% �ز���
% for i = 1:6
%     data_gensor_resample(i, :) = resample(data_imu(i, :), imu_time, fs_HZ);
% end

time_h = time/3600; 
figure()
plot(time_h, data_raw_gensor(3, :), '*');
grid on;
legend('acc-x')

figure()
plot(time_h, data_raw_gensor(4, :), '*');
grid on;
legend('acc-Y')

% figure()
% plot(time_h, data_raw_gensor(9, :), '*');
% grid on;
% legend('temp')

% figure()
% plot(time_h, data_raw_gensor(5, :), '*');
% grid on;
% legend('acc-Z')
% 
% figure()
% plot(time_h, data_raw_gensor(6, :), '*');
% grid on;
% legend('gyro-x')
% 
% figure()
% plot(time_h, data_raw_gensor(7, :), '*');
% grid on;
% legend('gyro-Y')
% 
% figure()
% plot(time_h, data_raw_gensor(8, :), '*');
% grid on;
% legend('gyro-Z')
