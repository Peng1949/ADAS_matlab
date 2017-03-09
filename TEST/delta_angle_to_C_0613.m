%%
% �Ƚ�����װ��������
% 1.ͳһת������ϵ�£�����k-1��kʱ�̵����Ҿ���
% 2.ֱ����ŷ���Ǳ仯�������㣨��������Ǵ�ģ���Ϊŷ����������û������ģ�
% 3.����̬�仯��Ԫ�����м��㣨�������ַ�����������֤OK��
%
% ע�⣺��̬�仯��Ԫ��q_h�ļ��㣬ʹ�õ�Ӧ���������ǵ�dtʱ���ڵĽ�����
% �˴�����ŷ���Ǳ仯������Ϊ��k-1ʱ�̵�ŷ����Ϊ0������FΪ��Ϊ��λ�󣩣�����С�Ƕȱ仯ʱ�����Խ�����Ϊŷ���Ǳ仯���������ǽ��������
% ���ԣ���������Ҳ���Կ�����Сŷ���Ǳ仯ʱ���ַ����������������ͬ���Ƕȴ��ʱ��ͻ��в���

%%
clear;
clc
% x y z
syms fai theta psi  dfai dtheta dpsi 
% fai = 0/pi;
% theta = 0/pi;
% psi = 0/pi;
% 
% dfai = 0.01/pi;
% dtheta = 0.01/pi;
% dpsi = 0.001/pi;


% k-1
C3_k_1 = [1  0  0;
          0 cos(fai) sin(fai);
          0 -sin(fai) cos(fai)];

C2_k_1 = [cos(theta) 0 -sin(theta);
                0    1    0;
            sin(theta) 0  cos(theta)];

C1_k_1 = [cos(psi) sin(psi) 0;
        -sin(psi) cos(psi) 0;
           0       0      1];
% k
 C3_k = [1  0  0;
        0 cos(fai+dfai) sin(fai+dfai);
        0 -sin(fai+dfai) cos(fai+dfai)];

C2_k = [cos(theta+dtheta) 0 -sin(theta+dtheta);
            0    1    0;
        sin(theta+dtheta) 0  cos(theta+dtheta)];

C1_k = [cos(psi+dpsi) sin(psi+dpsi) 0;
        -sin(psi+dpsi) cos(psi+dpsi) 0;
           0       0      1];


Ctk_n = C3_k*C2_k*C1_k;
Cn_tk_1 = (C3_k_1*C2_k_1*C1_k_1)';

% Ctk_n = expand(C3_k)*expand(C2_k)*expand(C1_k);
% Cn_tk_1 = (expand(C3_k_1)*expand(C2_k_1)*expand(C1_k_1))';
Ctk_tk_1 = Ctk_n*Cn_tk_1

% delta
C3_d = [1  0  0;
      0 cos(dfai) sin(dfai);
      0 -sin(dfai) cos(dfai)];

C2_d = [cos(dtheta) 0 -sin(dtheta);
                0    1    0;
            sin(dtheta) 0  cos(dtheta)];

C1_d = [cos(dpsi) sin(dpsi) 0;
        -sin(dpsi) cos(dpsi) 0;
           0       0      1];
Ctk_tk_1_d = C3_d*C2_d*C1_d
 

% ��Ԫ��
d_angle = sqrt(dfai^2 + dtheta^2 + dpsi^2);
sin_d_2 = sin(d_angle/2);
cos_d_2 = cos(d_angle/2);
q_h = [cos_d_2, dfai/d_angle*sin_d_2,  dtheta/d_angle*sin_d_2,  dpsi/d_angle*sin_d_2 ];
q0 = q_h(1);
q1 = q_h(2);
q2 = q_h(3);
q3 = q_h(4);

C_q = [q0^2+q1^2-q2^2-q3^2  2*(q1*q2-q0*q3) 2*(q1*q3+q0*q2)
        2*(q1*q2+q0*q3) q0^2-q1^2+q2^2-q3^2 2*(q2*q3-q0*q1)
        2*(q1*q3-q0*q2)  2*(q2*q3+q0*q1)   q0^2-q1^2-q2^2+q3^2]'




% Ctk_tk_1_d = C3_d*C2_d*C1_d


