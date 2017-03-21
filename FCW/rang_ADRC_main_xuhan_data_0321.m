%% 2017.03.13 �޸ĳ������Ӷ�����������������
% �޸�ģ�� �ı�Ϊ�ȼ���ģ��  Ч���ǳ���
%% 2017.03.18 ��Ӧ�µ����ݸ�ʽ������������������ͳ����������
% ��bounding box��Ϊ�������KF����
%% 2017.03.20  ����汾Ч����OK���������������ĺ����ٶȹ��ƺ�IMU�жϵ��������ȥ����
%% 2017.03.21 ��Ӧ�캭�����ݽṹ
% ����ADRC΢�ָ�����
clc
clear all
close all

%% ���ݵ���
% �����ļ���
% maindir = 'F:\����\FCW\0321_vison_radar\nj';
maindir = 'F:\����\FCW\0321_vison_radar\radar';
sub_l1_dir  = dir( maindir );
% һ��Ŀ¼
for l1_i = 1 : length( sub_l1_dir )
    if( isequal( sub_l1_dir(l1_i).name, '.' )|| isequal( sub_l1_dir(l1_i).name, '..')||  ~sub_l1_dir(l1_i).isdir)               % �������Ŀ¼������
        continue;
    end
    % ������Ŀ¼
    sub_l2_dir = dir(fullfile( maindir, sub_l1_dir(l1_i).name));
    for l2_i = 1 : 1
%         if( isequal( sub_l2_dir(l2_i).name, '.' )|| isequal( sub_l2_dir(l2_i).name, '..')||  ~sub_l2_dir(l2_i).isdir)               % �������Ŀ¼������
%             continue;
%         end
        subdirpath = fullfile( maindir, sub_l1_dir(l1_i).name, '*.critical' );
        txt_dir = dir( subdirpath );               % ���ļ������Һ�׺Ϊtxt���ļ�
        for txt_i = 1:length(txt_dir)
            log_addr = fullfile( maindir, sub_l1_dir(l1_i).name, txt_dir(txt_i).name);
            fid_log = fopen(log_addr, 'r');
            if ~fid_log
                break;
            end
            
           %% ��ʼ��
            ipm_step = 1; % ����
            is_first_read_timestamp = 1;
            time_start = 0; 
            
            speed_cur = 0;
            radar_data = [0  0 0 0]';
            radar_ttc = 0;
            % ��������
            struct_speed.data = 0;
            struct_speed.counter = 0;
            speed_update = 0; % �µ�speed���ݸ���
            radar_range_cur = 0;
            radar_vel_cur = 0;
            % �˲�
            is_first_read_camera_data = 1;
            is_kf_init_ok = 0; % KF�Ƿ��Ѿ����г�ʼ��
            is_first_radar_data = 1;
            save_i_index = 0; % ���ݴ洢����

            dv_filter = 0;
            is_first_vision_range = 1;
            fcw_state = 0;

            %% ��ѭ����ر���
            is_first_read_legal_data = 1;
            image_frame_id_pre = 0; % ��һ�μ���ʱ��image frame index ���ڼ���dt
            image_frame_T = 5*60/7744; % ��֡ͼƬ֮���dt  һ����Ƶ5min�������7744֡
            mobileye_fcw_state = 0; % mobileye fcw state  1��warning
            index_of_target_pre = 0; % ��һ֡Ŀ�공����ID
            is_new_target = 0; % �Ƿ�����Ŀ�공��            
            fcw_counter = 0; % ���㴥����������
            % ADRC
            is_ADRC_init_OK = 0;
          %% ��ѭ��
            read_txt_line = 0; % ��ȡ���ļ��������������<100  ��Ϊ���ļ�
            
            tt_state = feof(fid_log);
            while ~feof(fid_log) % ��ȡlog����    
                lineData = fgetl(fid_log);
                if lineData == -1
                    break;
                else
                    read_txt_line = read_txt_line + 1;
                end
                exp1 = ',';
                str_line_raw = regexp(lineData, exp1, 'split'); %�Կո�Ϊ�����ָ��ַ���
                str_frame_index = str2num(str_line_raw{1,1}); % ÿһ��ͼ��Ӧ3֡ 0:detect_vehicle_record    1:radar-recod  2��mobileye
                % Ϊ�˻�ͼ����  ��ȡ����ʱ�̵�ʱ��
                if is_first_read_timestamp
                    time_start = str2num(str_line_raw{1,2}); 
                    is_first_read_timestamp = 0;
                end

                % ��ȡmobileye ����
                % ������
                if(str_frame_index == 2)
                    mobileye_fcw_state = 1;
                end

                % 1: radar-recod      
                if(str_frame_index == 1)
                    speed_cur = str2num(str_line_raw{1,20+2});
                    radar_range = str2num(str_line_raw{1,19+2});
                    radar_range_vel = str2num(str_line_raw{1,16+2});
                    radar_range_acc = 0; %str2num(str_line_raw{1,14+2});
                    radar_horiz_dist = str2num(str_line_raw{1,18+2});
                    radar_data = [radar_range  radar_range_vel radar_range_acc radar_horiz_dist]';
                    
                    radar_ttc = str2num(str_line_raw{1,17+2});
                end
                
                % 0:   detect_vehicle_record 
                if(str_frame_index == 0)
                    % ���� index:0 ��ȡ����        
                    image_timestamp_cur = str2num(str_line_raw{1,2}) - time_start; 
                    image_frame_id = str2num(str_line_raw{1,4+2});
                    vison_range_raw = str2num(str_line_raw{1,10+2});
                    vision_horizon = str2num(str_line_raw{1,11+2});
                    index_of_target = str2num(str_line_raw{1,2+2});
                    ttc_raw = str2num(str_line_raw{1,14+2}); 

                    if(is_first_read_legal_data)
                        image_timestamp_pre = image_timestamp_cur;
                        is_first_read_legal_data = 0;
                    end 

                  %%  �˲�          
                    if(~is_kf_init_ok)
                        acc = 0;
                        speed_relative = 0;
                        vison_range_cur = vison_range_raw;
                        acc_h = 0;
                        speed_relative_h = 0;
                        vision_horizon_cur = vision_horizon;
                        Xk = [vison_range_cur, speed_relative, acc, vision_horizon_cur, speed_relative_h, acc_h ]';
                        Pk = diag([2, 4, 5, 1, 0.5, 0.5]);
                        Q = diag([5, 2, 5, 0.2, 0.5, 0.5]);
                        R = diag([4, 0.09]);      
                        is_kf_init_ok = 1;
                    end
                    
                    % �ж� target ID����ȷ���Ƿ���һ���µĳ�
                    if (index_of_target_pre ~= index_of_target)
                        is_new_target = 1;
                    else
                        is_new_target = 0;                        
                    end
                    index_of_target_pre = index_of_target;                    
                    dt_image = image_timestamp_cur - image_timestamp_pre;
                    image_timestamp_pre = image_timestamp_cur; 
                    % Ϊ�˴�����ʱ��û����Чǰ�������� dt̫���������˲�
                    % ������Ŀ�꣬ҲҪ�����˲�
                    if(dt_image > 0.3 || is_new_target)
                        % dt >1 ������
                        acc = 0;
                        speed_relative = 0;
                        vison_range_cur = vison_range_raw;
                        acc_h = 0;
                        speed_relative_h = 0;
                        vision_horizon_cur = vision_horizon;
                        Xk = [vison_range_cur, speed_relative, acc, vision_horizon_cur, speed_relative_h, acc_h ]';
                        Pk = diag([5, 4, 2, 1, 0.5, 0.5]);
                        Q = diag([5,2,5, 0.2, 0.5, 0.5]);
                        R = diag([4, 0.09]);  
                        % ADRC
                        ADRC_data = [0 0]';
                        v1 = vison_range_cur;
                        v2 = 0;
                    else
                        % ��ͨ�˲����� 
                        filt_hz = 0.5; % Ϊ�˿��Ʋ���  ����0.7�Ǽ��ޣ�>1֮��ͻ����복���������µĳ��ٱ仯��
                        [ vison_range_cur ] = fun_LowpassFilter( vison_range_cur, vison_range_raw, dt_image, filt_hz ); 

                        % KF �˲�
                        % X = [d, vs, vt]' ���࣬�����ٶȣ�Ŀ�공��
                        % z = [vision_range car_speed]                   
                        z = [vison_range_cur vision_horizon]';
                        F_sub = [1  dt_image  1/2*dt_image^2;
                                 0   1  dt_image;
                                 0   0  1];
                        O33 = zeros(3, 3);
                        F = [F_sub, O33;
                             O33, F_sub];
                        H = [1 0 0 0 0 0;
                              0 0 0 1 0 0];
                        [Xk, Pk] = fun_KF(Xk, Pk, z, Q, R, F, H);
                        
                     %%  ADRC΢�ָ�����
                        if ~is_ADRC_init_OK
                            v1 = vison_range_cur;
                            v2 = 0;
                            h_fhan = 0.0125; % for fhan
                            r = 100;
                            is_ADRC_init_OK = 1;
                        end
                        
                        h_step = dt_image; 
                        h_fhan = h_step*2;
                        v = vison_range_cur;                        
                        fh = fun_fhan(v1-v, v2, r, h_fhan);
                        v1 = v1 + h_step*v2;
                        v2 = v2 + h_step*fh;
                        ADRC_data = [v1, v2]';
                    end
                    
                  %% FCW�����߼��ж�
                    % ����ttc 
                    dv =  Xk(2);% vt-vs 
                    if abs(dv) >0.2
                        ttc = abs(Xk(1)/dv);
                    else
                        ttc = -1;
                    end
                    % fcw �����߼� ttc<4, ��Գ�����<20, ����>60/3.6, ˮƽ����<1.2, �ۼ�����5֡
                    % �����ж�mobileye�澯�ĳ������ǱȽϸ��ٵ�
                    % vel < -1
                    % �������Ӧ����˵�ǲ����� ���Կ�������һ�����ľ��� ��ֹ��
                    range_cur = Xk(1);
                    vel_cur = Xk(2);
                    acc_cur = Xk(3);
                    horizon_range = Xk(4);
                    horizon_vel = Xk(5); % �����ٶȴ���0.8��������Ŀǰ��������������⣩  % ��Ҫ�����Ƿ��Ѿ��ڼ���  && speed_cur>40/3.6
                    if(ttc<3.3 && ttc>0  && abs(vision_horizon)<2 && abs(horizon_vel)<0.6 && vel_cur<-1)  %  && range_cur<35 
                        fcw_counter = fcw_counter + 1;
                        if(fcw_counter >= 5)
                            fcw_state = 1;
                        else
                            fcw_state = 0;
                        end
                    else
                        fcw_counter = 0;
                        fcw_state = 0;
                    end
                    
                  %% ��������
                    time_cur = image_timestamp_cur;
                    save_i_index = save_i_index + 1;
                    save_Xk(:, save_i_index) = [time_cur; Xk];
                    save_vision_raw(:, save_i_index)= [time_cur; vison_range_raw];
                    save_ttc(:, save_i_index) = [time_cur; ttc ];
                    save_ttc_raw(:, save_i_index) = [time_cur; ttc_raw ];
                    save_dt_image(:, save_i_index) = [time_cur; dt_image];
                    save_fcw_state_mobileye(:, save_i_index) = [time_cur; mobileye_fcw_state];
                    save_fcw_state(:, save_i_index) = [time_cur;fcw_state ];
%                     save_data_mobileye_tmp(:, save_i_index) = [time_cur; data_mobileye_tmp];    
                    save_index_of_target(:, save_i_index) = [time_cur; index_of_target];       
                    save_vision_horizon(:, save_i_index) = [time_cur; vision_horizon];   
                    save_speed_car(:, save_i_index) = [time_cur; speed_cur];        
                    save_radar_data(:, save_i_index) = [time_cur; radar_data];   %  [radar_range  radar_range_vel radar_range_acc radar_horiz_dist]';
                    save_radar_ttc(:, save_i_index) = [time_cur; radar_ttc];   
                    % ADRC
                    save_ADRC_data(:, save_i_index) = [time_cur; ADRC_data];  
                    
                    % ����
                    mobileye_fcw_state = 0;
                end        
            end
            
            % ����100 �Ų��ǿ��ļ�
            if read_txt_line >100

            %     figure('visible','off')    
                h = figure();
                set(h,'outerposition',get(0,'screensize'));
                % ����
                ax1 = subplot(4,1,1);
                plot(save_vision_raw(1,:), save_vision_raw(2,:), '.'); % vision range ����
                hold on;
                plot(save_Xk(1,:), save_Xk(2,:), '.'); % range-estimate
                plot(save_ADRC_data(1,:), save_ADRC_data(2,:), '.'); % range-ADRC
                plot(save_radar_data(1,:), save_radar_data(2,:), '.'); % radar-range
                grid on;
                legend({'vision-range-measure-raw','range-estimate', 'range-ADRC', 'radar-range'},'Location','northeast','FontSize',10);
                legend('boxoff')
                log_addr_t = log_addr;
                str_name = sprintf('log�ļ�: %s \n ���� ', log_addr_t);
                title(str_name);

                % �ٶ� & ���ٶ� & �����ٶ�
                ax2 = subplot(4,1,2);
                plot(save_Xk(1,:), save_Xk(3, :), '.'); % vel estimation
                hold on;
                plot(save_ADRC_data(1,:), save_ADRC_data(3,:), '.'); % vel-ADRC
                plot(save_radar_data(1,:), -save_radar_data(3,:), '.'); % radar-vel                
                plot(save_Xk(1,:), save_Xk(5,:)*10, '.'); % vision-horizon*10
                plot(save_Xk(1,:), save_Xk(6,:)*10, '.'); % vision-horizon-vel*10                
                grid on;
                legend({'vel-estimation', 'vel-ADRC', 'radar-vel', 'vision-horizon*10', 'vision-horizon-vel*10'},'Location','northeast','FontSize',10);
    %             ylim([-30, 10]);
                legend('boxoff')
                title('�ٶ�&���ٶ�&�����ٶ�');

                % ������� & 
                ax4 = subplot(4,1,3);
                hold on;
                plot(save_Xk(1,:), save_Xk(4,:), '.'); % acc estimation
                plot(save_radar_data(1,:), -save_radar_data(4,:), '.'); % radar-acc
                plot(save_speed_car(1,:), save_speed_car(2,:), '.'); % speed-car
                grid on;
                legend({'acc-estimation','acc-estimation', 'radar-acc', 'speed-car'},'Location','northeast','FontSize',10);
    %             ylim([-30, 10]);
                legend('boxoff')
                title('�ٶ�&���ٶ�&�������&�����ٶ�');

                % ttc fcw
                ax3 = subplot(4,1,4);
                NUM1 = length(save_ttc);
                plot(save_ttc(1,:), save_ttc(2,:), '.'); % ttc
                hold on;
                plot(save_radar_ttc(1,:), save_radar_ttc(2,:), '.'); % radar-ttc            
                plot(save_fcw_state(1,:), save_fcw_state_mobileye(2,:)*5); % fcw_mobileye
                plot(save_fcw_state(1,:), save_fcw_state(2,:)*5); % fcw_minieye
                NUM = length(save_ttc(1,:));
                plot(save_ttc(1,:), ones(1,NUM)*3.3)
    %             plot(save_ttc(1,:), ones(1,NUM)*-4)
                grid on;
                legend({'ttc', 'radar-ttc', 'fcw-mobileye','fcw-minieye', 'ttc'},'Location','northeast','FontSize',10);
                legend('boxoff')
                str_name = sprintf('ttc&fcw');
                ylim([-1, 10]);
                title(str_name);

                linkaxes([ax1,ax2,ax3], 'x'); % ͬ����ͼ��������

                % ����figure
            %     filename=[log_addr_t, '--plot.png'];
            %     saveas(gcf,filename)
            %     close(gcf)    

                % ���������txt
            %     NUM = length(save_Xk);
            %     est_log_name = ['./data/est_result_new/', log_ID, '.log_KF_estimation.txt'];
            %     fp = fopen(est_log_name, 'wt');
            %     for i = 1:NUM
            %         fprintf(fp, '%d %f %f %f\n', save_Xk(1, i)/image_frame_T, save_Xk(2, i), save_Xk(3, i), save_Xk(4, i));
            %     end
            %     fclose(fp);
            % 
            end
            clear save_Xk  save_relative_v save_ttc save_vision_raw save_fcw_state save_data_mobileye_tmp...
                save_index_of_target save_vision_horizon save_dt_image save_speed_car save_ttc_raw save_fcw_state_mobileye...
                save_radar_data save_ADRC_data save_radar_ttc
            fclose(fid_log);

        end
    end
end

%% plot
% figure()
% plot(save_vision_raw(1,:), save_vision_raw(2,:)); % vision range ����
% hold on;
% plot(save_Xk(1,:), save_Xk(2,:)); % range-estimate
% plot(save_radar(1,:), save_radar(2,:)); % �״�
% grid on;
% legend('vision-range-measure-raw','range-estimate','radar-range');
% str_name = sprintf('���� ');
% title(str_name);
% 
% % �ٶ�
% figure()
% plot(save_relative_v(1,:), save_relative_v(2,:)); % vel estimation
% hold on;
% plot(save_radar(1,:), save_radar(3,:)); % �״��������ٶ�
% % plot(save_dv_radar_filter(1,:), save_dv_radar_filter(2,:)); % �״�����ֱ��΢�ֵ��ٶ�
% % plot(save_dv_filter(1,:), save_dv_filter(2,:)); % ֱ��΢�ֺ��ͨ�˲����ٶ�
% grid on;
% legend('vel-estimation', 'radar-vel', 'dv-�״�΢�ֺ��ͨ', 'dv-΢�ֺ��ͨ�˲�');
% title('�ٶ�');
% 
% % ���ٶ�
% figure()
% plot(save_Xk(1,:), save_Xk(4,:)); % acc estimation
% hold on;
% plot(save_radar(1,:), save_radar(4,:)); % �״����acc
% grid on;
% legend('acc-estimation', 'radar-acc');
% title('���ٶ�');
% 
% % ttc fcw
% figure()
% plot(save_ttc(1,:), save_ttc(2,:)); % ttc
% hold on;
% plot(save_fcw_state(1,:), save_fcw_state(2,:)*20); % fcw_mobileye
% NUM = length(save_ttc(1,:));
% plot(save_ttc(1,:), ones(1,NUM)*4)
% plot(save_ttc(1,:), ones(1,NUM)*-4)
% grid on;
% legend('ttc', 'fcw-mobileye');
% title('ttc&fcw');
