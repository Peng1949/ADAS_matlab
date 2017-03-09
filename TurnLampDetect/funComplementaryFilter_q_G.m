% ���ڲ�����̬��֪  ����Ҫ��ֹg̫���ʱ��
% ������Ԫ��������̬�������
function [att, Q_new, AccAngle] = funComplementaryFilter_q_G(Q, acc, gyro, dt )
    % ZYX
    AccAngle = zeros(2,1);
    AccAngle(1) = atan2(-acc(2), -acc(3)); % roll
    AccAngle(2) = atan2(acc(1), sqrt(acc(2)^2 + acc(3)^2));    
    
    % ���ݼ��ٶȼ������ģֵ���������ٶȼƵ�ϵ��
    acc_normal = sqrt(sum(acc.^2));
    if acc_normal < 1.05*9.8 && acc_normal > 0.95*9.8
        mFactorAccAngle = 0.01;     
    else
        mFactorAccAngle = 0.0005; 
    end
    
    dTheta = gyro*dt;
    dtheta = sqrt(sum(dTheta.^2));
    temp1 = (dTheta/dtheta)*sin(dtheta/2);
    q_h = [cos(dtheta/2), temp1(1), temp1(2), temp1(3)]';
    Q = funQqCross(Q,q_h );
    att_w = funQuat2Euler( Q ); % �����Ϊֹ��OK��
    
    att = zeros(3,1);
    att(1) = att_w(1) + mFactorAccAngle*( AccAngle(1) - att_w(1));
    att(2) = att_w(2) + mFactorAccAngle*( AccAngle(2) - att_w(2));
    att(3) = att_w(3);        
    Q_new  = funEuler2Quat( att );

end

