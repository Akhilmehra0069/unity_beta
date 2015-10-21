public without sharing class CommunityAccess {

	private static final Boolean IsGuestUser = (UserInfo.getUserType() == 'Guest');
	public static final String AccessViolationException = 'Access Restricted';

	// Access
	public static void ThrowAccessException(Schema.DescribeSObjectResult soDescribe) {
		throw new CommunityAccessException(
			AccessViolationException,
			CommunityAccessException.ExceptionType.OBJECT_ACCESS_VIOLATION,
			CommunityAccessException.ExceptionReason.GENERIC,
			soDescribe.getName(),
			NULL
		);
	}

	// Insert
	public static Database.SaveResult InsertWithoutSharing(sObject obj, String err, Schema.DescribeFieldResult[] fields) {
		FLSAccessControllerWithSharing acws = new FLSAccessControllerWithSharing();
		String notCreateableFLS = acws.hasNotCreateableFLS(fields);
		if (notCreateableFLS != NULL) {
			throw new CommunityAccessException(
				AccessViolationException,
				CommunityAccessException.ExceptionType.FIELD_ACCESS_VIOLATION,
				CommunityAccessException.ExceptionReason.NO_CREATE,
				obj.getSObjectType().getDescribe().getName(),
				notCreateableFLS
			);
		}
		return Database.insert(obj);
	}

	public static Database.SaveResult[] InsertWithoutSharing(sObject[] objs, String err, Schema.DescribeFieldResult[] fields) {
		FLSAccessControllerWithSharing acws = new FLSAccessControllerWithSharing();
		String notCreateableFLS = acws.hasNotCreateableFLS(fields);
		if (notCreateableFLS != NULL) {
			throw new CommunityAccessException(
				AccessViolationException,
				CommunityAccessException.ExceptionType.FIELD_ACCESS_VIOLATION,
				CommunityAccessException.ExceptionReason.NO_CREATE,
				objs.getSObjectType().getDescribe().getName(),
				notCreateableFLS
			);
		}
		return Database.insert(objs);
	}

	// Update
	public static Database.SaveResult UpdateWithoutSharing(sObject obj, String err, Schema.DescribeFieldResult[] fields) {
		FLSAccessControllerWithSharing acws = new FLSAccessControllerWithSharing();
		String notUpdateableFLS = (IsGuestUser && !obj.getSObjectType().getDescribe().isCustom()) ? acws.hasNotCreateableFLS(fields) : acws.hasNotUpdateableFLS(fields);
		if (notUpdateableFLS != NULL) {
			throw new CommunityAccessException(
				AccessViolationException,
				CommunityAccessException.ExceptionType.FIELD_ACCESS_VIOLATION,
				CommunityAccessException.ExceptionReason.NO_UPDATE,
				obj.getSObjectType().getDescribe().getName(),
				notUpdateableFLS
			);
		}
		return Database.update(obj);
	}
	public static Database.SaveResult[] UpdateWithoutSharing(sObject[] objs, String err, Schema.DescribeFieldResult[] fields) {
		FLSAccessControllerWithSharing acws = new FLSAccessControllerWithSharing();
		String notUpdateableFLS = (IsGuestUser && !objs.getSObjectType().getDescribe().isCustom()) ? acws.hasNotCreateableFLS(fields) : acws.hasNotUpdateableFLS(fields);
		if (notUpdateableFLS != NULL) {
			throw new CommunityAccessException(
				AccessViolationException,
				CommunityAccessException.ExceptionType.FIELD_ACCESS_VIOLATION,
				CommunityAccessException.ExceptionReason.NO_UPDATE,
				objs.getSObjectType().getDescribe().getName(),
				notUpdateableFLS
			);
		}
		return Database.update(objs);
	}

	// Upsert
	public static Database.UpsertResult UpsertWithoutSharing(sObject obj, String err, Schema.DescribeFieldResult[] fields) {
		FLSAccessControllerWithSharing acws = new FLSAccessControllerWithSharing();
		String notCreateableFLS = acws.hasNotCreateableFLS(fields);
		String notUpdateableFLS = (IsGuestUser && !obj.getSObjectType().getDescribe().isCustom()) ? notCreateableFLS : acws.hasNotUpdateableFLS(fields);
		if (notCreateableFLS != NULL || notUpdateableFLS != NULL) {
			throw new CommunityAccessException(
				AccessViolationException,
				CommunityAccessException.ExceptionType.FIELD_ACCESS_VIOLATION,
				(notCreateableFLS!=NULL) ? CommunityAccessException.ExceptionReason.NO_CREATE : CommunityAccessException.ExceptionReason.NO_UPDATE,
				obj.getSObjectType().getDescribe().getName(),
				(notCreateableFLS!=NULL) ? notCreateableFLS : notUpdateableFLS
			);
		}
		return Database.upsert(obj);
	}
	public static Database.UpsertResult[] UpsertWithoutSharing(sObject[] objs, String err, Schema.DescribeFieldResult[] fields) {
		FLSAccessControllerWithSharing acws = new FLSAccessControllerWithSharing();
		String notCreateableFLS = acws.hasNotCreateableFLS(fields);
		String notUpdateableFLS = (IsGuestUser && !objs.getSObjectType().getDescribe().isCustom()) ? notCreateableFLS : acws.hasNotUpdateableFLS(fields);
		if (notCreateableFLS != NULL || notUpdateableFLS != NULL) {
			throw new CommunityAccessException(
				AccessViolationException,
				CommunityAccessException.ExceptionType.FIELD_ACCESS_VIOLATION,
				(notCreateableFLS!=NULL) ? CommunityAccessException.ExceptionReason.NO_CREATE : CommunityAccessException.ExceptionReason.NO_UPDATE,
				objs.getSObjectType().getDescribe().getName(),
				(notCreateableFLS!=NULL) ? notCreateableFLS : notUpdateableFLS
			);
		}
		return Database.upsert(objs);
	}

	// Delete
	public static Database.DeleteResult DeleteWithoutSharing(sObject obj, String err) {
		FLSAccessControllerWithSharing acws = new FLSAccessControllerWithSharing();
		Boolean isObjectDeletable = (!obj.getSObjectType().getDescribe().isCustom()) ? acws.isObjectCreateable(obj) : acws.isObjectDeletable(obj);
		if (isObjectDeletable == false) {
			throw new CommunityAccessException(
				AccessViolationException,
				CommunityAccessException.ExceptionType.OBJECT_ACCESS_VIOLATION,
				CommunityAccessException.ExceptionReason.NO_DELETE,
				obj.getSObjectType().getDescribe().getName(),
				NULL
			);
		}
		return Database.delete(obj);
	}
	public static Database.DeleteResult[] DeleteWithoutSharing(sObject[] objs, String err) {
		FLSAccessControllerWithSharing acws = new FLSAccessControllerWithSharing();
		Boolean isObjectsDeletable = (!objs.getSObjectType().getDescribe().isCustom()) ? acws.isObjectsCreateable(objs) : acws.isObjectsDeletable(objs);
		if (isObjectsDeletable == false) {
			throw new CommunityAccessException(
				AccessViolationException,
				CommunityAccessException.ExceptionType.OBJECT_ACCESS_VIOLATION,
				CommunityAccessException.ExceptionReason.NO_DELETE,
				objs.getSObjectType().getDescribe().getName(),
				NULL
			);
		}
		return Database.delete(objs);
	}

	private with sharing class FLSAccessControllerWithSharing {
		public String hasNotCreateableFLS(Schema.DescribeFieldResult[] fields) {
			String result = NULL;
			for (Schema.DescribeFieldResult field : fields) {
				Boolean isCreateable = field.isCreateable();
				if (!isCreateable) {
					result = field.getName();
					break;
				}
			}
			return result;
		}
		public String hasNotUpdateableFLS(Schema.DescribeFieldResult[] fields) {
			String result = NULL;
			for (Schema.DescribeFieldResult field : fields) {
				// For Master-Detail fields check for Creatable instead of Updateable access
				Boolean isUpdateable = (field.getRelationshipOrder() != NULL) ? field.isCreateable() : field.isUpdateable();
				if (!isUpdateable) {
					result = field.getName();
					break;
				}
			}
			return result;
		}
		public Boolean isObjectCreateable(sObject obj) {
			return obj.getSObjectType().getDescribe().isCreateable();
		}
		public Boolean isObjectsCreateable(sObject[] objs) {
			return objs.getSObjectType().getDescribe().isCreateable();
		}
		public Boolean isObjectDeletable(sObject obj) {
			return obj.getSObjectType().getDescribe().isDeletable();
		}
		public Boolean isObjectsDeletable(sObject[] objs) {
			return objs.getSObjectType().getDescribe().isDeletable();
		}
	}
}