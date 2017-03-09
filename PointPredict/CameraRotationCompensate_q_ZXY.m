% �ı�ת��˳�򣬿��Զ�������������н���
% �����ƻ������м��Ǹ�ת���ǽӽ�80���ʱ����б任ת��˳�򣨵���Ҫע��һ�㣬���������ŷ����������ܾ��ǲ�һ���ˣ�����Ҫע�⣩
clc;
clear all
close all

%% ��ȡ����
% data = load('1.ˮƽ+pitchת��+ƽ��.mat');
% data = load('2.ƽ��.mat');
% data = load('3.ˮƽ��ֹ.mat');
% data = load('4.pitch=90_�ٶ�pitch.mat');
data = load('5.pitch��.mat');


IMU_time1 = data.IMU(:, 2)'*1e-6; %
IMU_time = IMU_time1;
acc_raw =  data.IMU(:, 6:8)';
gyro_raw = data.IMU(:, 3:5)'; % rad/s

% roll pitch yaw
att_ekf = [data.ATT(:,4), data.ATT(:,6), data.ATT(:,8)]';% apm��EKF�õ�����̬����
att_q = [data.AHR2(1:end-1,3), data.AHR2(1:end-1,4), data.AHR2(1:end-1,5)]'; % apm�����˲��õ�����̬����
att_ekf_time = data.ATT(:,2)'*1e-6;
att_q_time = data.AHR2(1:end-1,2)'*1e-6;

% ��ʼ������
acc_filter = [0, 0, 0]'; % һ�׵�ͨ��ļ��ٶȼ�ֵ
gyro_fiter = [0, 0, 0]';
acc_lowfilt_hz = 5; % ���ٶȼƵ�ͨ��ֹƵ��

att = zeros(3,1);
GyroAngle = zeros(3,1);
Q = [1 0 0 0]';
Q1 = Q;
j=1;

dt_err_num = 0; % dt = 0ʱ��+1
%%
NUM = length(IMU_time1);
for i = 2:NUM
%     IMU_time(i) = i;
    if i == 7090
        kk=1;
    end
    
    dt = (IMU_time1(i) - IMU_time1(i-1));
    if dt==0
        dt_err_num = dt_err_num + 1;
    end
    
% IMU����һ�׵�ͨ�˲�
    acc_new =  acc_raw(: , i);
    [ acc_filter ] = funLowpassFilterVector3f( acc_filter, acc_new, dt, acc_lowfilt_hz );
    acc_filter_save(:,i-1) = acc_filter;
%�����˲�
    gyro_fiter = gyro_raw(: , i);
%     [ att, AccAngle ] = funComplementaryFilter(att, acc_filter, gyro_fiter, dt, 1e-4 );
%     [att, Q , w_I, w_P] = funComplementaryFilter_q(Q, acc_filter, gyro_fiter, dt );    
    [att, Q ,AccAngle] = funComplementaryFilter_q_ZXY(Q, -acc_filter, gyro_fiter, dt ); 
    
%     [ att, AccAngle ] = funComplementaryFilter_ZXY(att,-acc_filter, gyro_fiter, dt, 0 ); % OK��
   
    IMU_trim = [0.002248888, 0.04422353, 0]'*180/pi;
    
    att_save(:,i-1) = att*180/pi - IMU_trim;
    AccAngle_save(:,i-1) = AccAngle*180/pi - IMU_trim(1:2);
    GyroAngle_save(:,i-1) = GyroAngle*180/pi - IMU_trim;
    
%     w_I_save(:,i-1) = w_I;
%     w_P_save(:,i-1) = w_P;
end

figure()
plot(IMU_time(2:end),att_save(1, :));
hold on;
grid on;
plot(IMU_time(2:end), AccAngle_save(1, :));
% plot(IMU_time(2:end), GyroAngle_save(1, :));
plot(att_q_time, att_q(1, :));
legend('att', 'AccAngle','q');

figure()
plot(IMU_time(2:end), att_save(2, :));
hold on;
grid on;
plot(IMU_time(2:end), AccAngle_save(2, :));
% plot(IMU_time(2:end), GyroAngle_save(2, :));
plot(att_q_time, att_q(2, :));
legend('att', 'AccAngle','q');

figure()
plot(IMU_time(2:end), att_save(3, :));
hold on;
grid on;
% plot(IMU_time(2:end), AccAngle_save(3, :));
% plot(IMU_time(2:end), GyroAngle_save(2, :));
plot(att_q_time, att_q(3, :)-mean(att_q(3, 10:50)));
legend('att', 'q' );
