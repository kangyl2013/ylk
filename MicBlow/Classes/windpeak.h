//短时能量峰值


double energy(short *data,int point)//求帧能量。data为输入数据数组的地址，point为数组中的数据个数
{	
	int i;
	double e=0;
	for(i=0;i<point;i++)
		e+=(pow(*(data+i),2));
	return e/(1000*point);
}