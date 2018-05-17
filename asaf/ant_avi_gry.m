function ant_avi_gry(avi,aviout)



vr = VideoReader(avi);
vw = VideoWriter(aviout);
nframes = vr.NumberOfFrames;
fps = vr.FrameRate;
vw.FrameRate = fps;
open(vw);


for i=1:nframes
    
    image=read(vr,i);
    image=min(image,[],3);
    image=imadjust(image);
    image=imsharpen(image);
    image=imcomplement(image);
    image=imfill(image,4);
    %aligned = align_ant(image);
    writeVideo(vw,image);
    
end

close(vw)