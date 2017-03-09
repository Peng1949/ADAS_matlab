% ��ʾ�˹���ע�ĵ�
clc;
clear all; 
close all

SAVE_R = 0; % ����R
SHOW_IPM = 1; % �Ƿ�����IPM��ʾת��뾶 
%% ���ݵ���
% ת��뾶
source_addr = 'data/1013_���ٱ��/';

% ������������ ����������ÿ��8��������
address_lane = [source_addr, 'lane_feature_122230_700_900.txt'];
lane_feature_raw_data = load(address_lane)'; % data_lane: lane index*1, ���ҳ����ֱ�8����
NUM_lane = length(lane_feature_raw_data(1, :)); % ��������
lane_feature_data.frame_index = lane_feature_raw_data(1, :);
for i = 1:8
    lane_feature_data.left_uv_feature(i, :, :) = lane_feature_raw_data(2*i:2*i+1, :);
    lane_feature_data.right_uv_feature(i, :, :) = lane_feature_raw_data(2*i+16:2*i+17, :);
end

for k_lane = 1:1:NUM_lane
    k = lane_feature_data.frame_index(k_lane);

    % ��ȡͼƬ����
    image_name = sprintf('/%08d.jpg',k);
    str_data = [source_addr, '122230_����/',image_name];
    I_rgb = imread(str_data);
    I_g = rgb2gray(I_rgb);
    [m, n] = size(I_g);

    for i = 1:8
         u_L = lane_feature_data.left_uv_feature(i, 1, k_lane);
         v_L = lane_feature_data.left_uv_feature(i, 2, k_lane);
         u_R = lane_feature_data.right_uv_feature(i, 1, k_lane);
         v_R = lane_feature_data.right_uv_feature(i, 2, k_lane);

         value_t = 230;
         I_rgb(v_L+1:v_L+3, u_L+1:u_L+3) = value_t;

         value_t = 0;
         I_rgb(v_R+1:v_R+3, u_R+1:u_R+3) = value_t;

    end

    figure(1);
    str_name = sprintf('frame%d',k);
    title(str_name); 
    imshow(I_rgb);    
end
        

