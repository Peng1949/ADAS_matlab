%%   ����ѹ����Ĥ+����IMU�����IMU  ����ת��Ƹ�֪

clc
clear 
close all
%% IMU ����Ԥ����
origin_address = ['data/0907/'];
origin_name = '0907_turnlamp_log-';

% data_att_IMU = [imu_time; att*180/pi; acc_cal; gyro_cal]';
address_att_IMU = [origin_address, 'data_att_IMU_0907.mat'];
load(address_att_IMU);
data_att_C = data_att_IMU(1:4, :); % �������̬
time_start = data_att_C(1, 1);
data_att_C(1, :) = data_att_C(1, :) - time_start; % ��ʱ��ͳһ��ͬһ�����

% att_G ����att 
address_att_G = [origin_address, origin_name, 'att.ini'];
data_raw_att_G =  load(address_att_G);
data_raw_att_G = data_raw_att_G';
time_s = data_raw_att_G(1, :);
time_us = data_raw_att_G(2, :);
time = time_s + time_us *1e-6 - time_start;
data_att_G = [time; data_raw_att_G(3:5, :)/10];

% turnlamp ת����źţ�0 No steering light 1 Left steering light��2 Right steering light";
% address_turnlamp = [origin_address, origin_name, 'turnlamp.ini'];
% data_raw_turnlamp =  load(address_turnlamp);
% data_raw_turnlamp = data_raw_turnlamp';
% time_s = data_raw_turnlamp(1, :);
% time_us = data_raw_turnlamp(2, :);
% time = time_s + time_us *1e-6 - time_start;
% turnlamp_NUM = length(time);
% turnlamp_t(1, :) = data_raw_turnlamp(3, :);
% for i = 1:turnlamp_NUM
%     if data_raw_turnlamp(3, i) == 2
%         turnlamp_t(1, i) = -1;
%     end        
% end
% data_turnlamp = [time; turnlamp_t];

% adc ѹ����Ĥ
% address_adc = [origin_address, origin_name, 'adc.ini'];
% data_adc =  load(address_adc);
% data_adc = data_adc';
% time_s = data_adc(1, :);
% time_us = data_adc(2, :);
% time = time_s + time_us *1e-6 - time_start;
% adc = [time; data_adc(3:4, :)];

%% �����ز���
fs_HZ = 40;
data_att_C_resample(1, :) = resample(data_att_C(2,:), data_att_C(1,:), fs_HZ);
data_att_C_resample(2, :) = resample(data_att_C(3,:), data_att_C(1,:), fs_HZ);
data_att_C_resample(3, :) = resample(data_att_C(4,:), data_att_C(1,:), fs_HZ);

data_att_G_resample(1, :) = resample(data_att_G(2,:), data_att_G(1,:), fs_HZ);
data_att_G_resample(2, :) = resample(data_att_G(3,:), data_att_G(1,:), fs_HZ);
data_att_G_resample(3, :) = resample(data_att_G(4,:), data_att_G(1,:), fs_HZ);


%% ����
NUM = length(data_att_G_resample) - 50;
for i = 1:NUM
    att_C = data_att_C_resample(:, i)/180*pi;
    att_C(3) = 0;
    [ R_C ] = funAtt2Rnb( att_C );
    
    att_G = data_att_G_resample(:, i)/180*pi;
    att_G(3) = 0;
    [ R_G ] = funAtt2Rnb( att_G );
    
    R_new = R_G*R_C';
    
    roll = atan2(R_new(2,3), R_new(3,3));
    pitch = asin(-R_new(1,3));
    yaw = atan2(R_new(1,2), R_new(1,1));
    
    att_new_save(:,i) = [roll; pitch; yaw]*180/pi;
end

% ԭʼ����
figure()
subplot(3,1,1)
plot(data_att_C_resample(1,:));
hold on;
plot(data_att_G_resample(1, :));
grid on;
legend('att-X-C', 'att-X-G');

subplot(3,1,2)
plot(data_att_C_resample(2,:));
hold on;
plot(data_att_G_resample(2, :));
grid on;
legend('att-Y-C', 'att-Y-G');

subplot(3,1,3)
plot(data_att_C_resample(3,:));
hold on;
plot(data_att_G_resample(3, :));
grid on;
legend('att-Z-C', 'att-Z-G');

% �����̬
figure()
subplot(3,1,1)
plot(att_new_save(1,:)- mean(att_new_save(1,1:10)));
hold on;
% plot(data_turnlamp_resample*10);
grid on;
legend('att-X', 'turnlamp');

subplot(3,1,2)
plot(att_new_save(2,:) - mean(att_new_save(2,1:10)));
hold on;
% plot(data_turnlamp_resample*10);
grid on;
legend('att-Y', 'turnlamp');

subplot(3,1,3)
plot(att_new_save(3,:));
hold on;
% plot(data_turnlamp_resample*10);
grid on;
legend('att-Z', 'turnlamp');

%
% figure()
% subplot(3,1,1)
% plot(att_C(1, :), att_C(2, :)); %camera: X
% hold on;
% plot(att_G(1, :), att_G(2, :) - mean(att_G(2, :)) ); % gan:X  - mean(att_G(2, :))
% plot(turnlamp(1, :), turnlamp(2, :)*10); 
% grid on;
% legend('����ͷ-X', '��-X', 'turnlamp', '��-Y');
% 
% subplot(3,1,2)
% plot(att_C(1, :), att_C(3, :)); %camera: Y
% hold on;
% plot(att_G(1, :), att_G(3, :) - mean(att_G(3, :)) ); % gan:Y
% plot(turnlamp(1, :), turnlamp(2, :)*10); 
% grid on;
% legend('����ͷ-Y', '��-Y', 'turnlamp');
% 
% subplot(3,1,3)
% plot(att_C(1, :), att_C(4, :)); %camera: Z
% hold on;
% plot(att_G(1, :), att_G(4, :)); % gan: Z
% grid on;
% legend('����ͷ-Z', '��-Z');


% figure()
% plot(adc(1, :), adc(2, :));
% hold on;
% plot(adc(1, :), adc(3, :));
% grid on;
% legend('adc-��', 'adc-��');


