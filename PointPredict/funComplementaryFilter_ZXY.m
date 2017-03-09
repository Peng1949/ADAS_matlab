function [ att, AccAngle ] = funComplementaryFilter_ZXY(att, acc, gyro, dt, mFactorAccAngle )
%     mFactorAccAngle = 0; % ���ٶȼƽǶȵ�Ȩֵ��������ʹ�ù̶�ֵ����������ݼ��ٶȲ�����������ñ�ϵ��
    roll = att(1);
    pitch = att(2);
    yaw = att(3);
    
    % acc angle
    AccAngle = zeros(2,1);
    AccAngle(1) = atan2(acc(2), sqrt(acc(1)^2 + acc(3)^2));  % roll
    AccAngle(2) = atan2(-acc(1), acc(3));
    
    
    if dt>2.5e-4 && cos(pitch)~=0
        
        F_w2euler = [cos(pitch)  0  -cos(roll)*sin(pitch);
                         0       1    sin(roll);
                         sin(pitch)  0    cos(roll)*cos(pitch)];
                 
        gyro_euler = inv(F_w2euler)*gyro;
        
        att(1) = (att(1) + gyro_euler(1)*dt) + mFactorAccAngle*( AccAngle(1) - att(1));
        att(2) = (att(2) + gyro_euler(2)*dt) + mFactorAccAngle*( AccAngle(2) - att(2));
        att(3) = (att(3) + gyro_euler(3)*dt);
    end

end
