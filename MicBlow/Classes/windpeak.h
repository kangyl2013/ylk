//��ʱ������ֵ


double energy(short *data,int point)//��֡������dataΪ������������ĵ�ַ��pointΪ�����е����ݸ���
{	
	int i;
	double e=0;
	for(i=0;i<point;i++)
		e+=(pow(*(data+i),2));
	return e/(1000*point);
}