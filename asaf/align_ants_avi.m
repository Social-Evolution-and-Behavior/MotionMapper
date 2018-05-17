function align_ants_avi(avi,aviout)


vr = VideoReader(avi);
vw = VideoWriter(aviout);
nframes = vr.NumberOfFrames;
fps = vr.FrameRate;
vw.FrameRate = fps;
open(vw);




for i=1:1000
    
    image=read(vr,i);
    aligned = align_ant(image);
    writeVideo(vw,aligned);
    
end


close(vw)
    




