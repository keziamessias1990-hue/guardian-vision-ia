import { Controller, Get } from '@nestjs/common';

export interface ChildRecord {
  id: string;
  parentId: string;
  name: string;
  ageGroup: string;
  status: 'linked' | 'pending';
  createdAt: string;
}

@Controller('children')
export class ChildrenController {
  @Get()
  findAll(): ChildRecord[] {
    return [
      {
        id: 'child-1',
        parentId: 'parent-1',
        name: 'Ana',
        ageGroup: '12-14',
        status: 'linked',
        createdAt: '2026-11-12T08:00:00.000Z',
      },
      {
        id: 'child-2',
        parentId: 'parent-1',
        name: 'Lucas',
        ageGroup: '15-17',
        status: 'linked',
        createdAt: '2026-11-12T08:30:00.000Z',
      },
    ];
  }
}
