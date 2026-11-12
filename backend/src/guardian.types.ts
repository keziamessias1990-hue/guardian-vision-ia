export type RiskSeverity = 'low' | 'medium' | 'high';
export type RiskCategory =
  | 'secret-sharing'
  | 'platform-change'
  | 'personal-data-request';
export type AlertState = 'pending' | 'acknowledged' | 'dismissed';

export interface ParentRecord {
  id: string;
  name: string;
  email: string;
  createdAt: string;
}

export interface ChildRecord {
  id: string;
  parentId: string;
  name: string;
  ageGroup: string;
  status: 'pending' | 'linked';
  createdAt: string;
}

export interface RiskAlertRecord {
  id: string;
  childId: string;
  category: RiskCategory;
  severity: RiskSeverity;
  source: 'guardian_kids' | 'demo';
  summary: string;
  occurredAt: string;
  confirmationState: AlertState;
}

export interface LoginRequestDto {
  email: string;
  password?: string;
}

export interface CreateParentDto {
  name: string;
  email: string;
}

export interface CreateChildDto {
  parentId: string;
  name: string;
  ageGroup: string;
}

export interface CreateAlertDto {
  childId: string;
  category: RiskCategory;
  severity: RiskSeverity;
  source?: 'guardian_kids' | 'demo';
  summary?: string;
}

export interface LoginResponseDto {
  token: string;
  parent: ParentRecord;
}
